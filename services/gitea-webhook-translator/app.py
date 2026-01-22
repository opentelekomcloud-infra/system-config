#!/usr/bin/env python3
"""
Gitea to GitHub Webhook Translator for Zuul
Converts Gitea webhook payloads to GitHub format for Zuul processing
"""
import hashlib
import hmac
import json
import logging
import os
from typing import Dict, Any

import requests
from fastapi import FastAPI, Request, Response, HTTPException
from fastapi.responses import JSONResponse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Gitea to GitHub Webhook Translator")

# Configuration
ZUUL_WEBHOOK_URL = os.getenv("ZUUL_WEBHOOK_URL", "http://zuul-web:9000/api/connection/github/payload")
GITHUB_WEBHOOK_SECRET = os.getenv("GITHUB_WEBHOOK_SECRET", "")
GITEA_WEBHOOK_SECRET = os.getenv("GITEA_WEBHOOK_SECRET", "")


def verify_gitea_signature(payload: bytes, signature: str) -> bool:
    """Verify Gitea webhook signature"""
    if not GITEA_WEBHOOK_SECRET:
        logger.warning("GITEA_WEBHOOK_SECRET not set, skipping signature verification")
        return True
    
    expected = hmac.new(
        GITEA_WEBHOOK_SECRET.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(expected, signature)


def sign_github_payload(payload: bytes) -> str:
    """Generate GitHub webhook signature"""
    signature = hmac.new(
        GITHUB_WEBHOOK_SECRET.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return f"sha256={signature}"


def convert_gitea_to_github(gitea_payload: Dict[str, Any], event_type: str) -> Dict[str, Any]:
    """Convert Gitea webhook payload to GitHub format"""
    
    # For push events, Gitea and GitHub formats are very similar
    if event_type == "push":
        # Gitea format is already compatible with GitHub push events
        return gitea_payload
    
    # For pull_request events
    if event_type == "pull_request":
        # Map Gitea PR actions to GitHub actions
        action_map = {
            "opened": "opened",
            "closed": "closed",
            "reopened": "reopened",
            "edited": "edited",
            "synchronized": "synchronize",
            "assigned": "assigned",
            "unassigned": "unassigned",
            "review_requested": "review_requested",
            "review_request_removed": "review_request_removed",
            "labeled": "labeled",
            "unlabeled": "unlabeled",
        }
        
        action = gitea_payload.get("action", "")
        github_action = action_map.get(action, action)
        
        # Convert pull_request structure
        github_payload = {
            "action": github_action,
            "number": gitea_payload.get("number"),
            "pull_request": gitea_payload.get("pull_request", {}),
            "repository": gitea_payload.get("repository", {}),
            "sender": gitea_payload.get("sender", {}),
        }
        
        return github_payload
    
    # Default: return as-is
    logger.warning(f"Unknown event type: {event_type}, returning payload as-is")
    return gitea_payload


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy"}


@app.post("/webhook")
async def gitea_webhook(request: Request):
    """
    Receive Gitea webhook, convert to GitHub format, and forward to Zuul
    """
    try:
        # Get headers
        gitea_event = request.headers.get("X-Gitea-Event", "")
        gitea_signature = request.headers.get("X-Gitea-Signature", "")
        gitea_delivery = request.headers.get("X-Gitea-Delivery", "")
        
        logger.info(f"Received Gitea webhook: event={gitea_event}, delivery={gitea_delivery}")
        
        # Read payload
        payload_bytes = await request.body()
        
        # Verify Gitea signature
        if gitea_signature and not verify_gitea_signature(payload_bytes, gitea_signature):
            logger.error("Invalid Gitea webhook signature")
            raise HTTPException(status_code=401, detail="Invalid signature")
        
        # Parse JSON payload
        try:
            gitea_payload = json.loads(payload_bytes)
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON payload: {e}")
            raise HTTPException(status_code=400, detail="Invalid JSON")
        
        # Convert to GitHub format
        github_payload = convert_gitea_to_github(gitea_payload, gitea_event)
        github_payload_bytes = json.dumps(github_payload).encode()
        
        # Sign with GitHub secret
        github_signature = sign_github_payload(github_payload_bytes)
        
        # Prepare headers for Zuul
        zuul_headers = {
            "Content-Type": "application/json",
            "User-Agent": "Gitea-Webhook-Translator/1.0",
            "X-GitHub-Event": gitea_event,
            "X-GitHub-Delivery": gitea_delivery,
            "X-Hub-Signature-256": github_signature,
        }
        
        # Forward to Zuul
        logger.info(f"Forwarding to Zuul: {ZUUL_WEBHOOK_URL}")
        response = requests.post(
            ZUUL_WEBHOOK_URL,
            data=github_payload_bytes,
            headers=zuul_headers,
            timeout=30
        )
        
        logger.info(f"Zuul response: status={response.status_code}")
        
        return JSONResponse(
            status_code=response.status_code,
            content={"message": "Webhook forwarded", "zuul_status": response.status_code}
        )
        
    except Exception as e:
        logger.error(f"Error processing webhook: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)

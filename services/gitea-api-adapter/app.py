"""
Gitea API Adapter - Translates GitHub API v3 to Gitea API v1
This proxy allows Zuul's GitHub driver to work with Gitea by translating API calls.
"""

import os
import logging
from typing import Optional
from fastapi import FastAPI, Request, Response, HTTPException
from fastapi.responses import JSONResponse
import httpx

# Configure logging
logging.basicConfig(
    level=logging.DEBUG if os.getenv("DEBUG", "false").lower() == "true" else logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Gitea API Adapter", description="GitHub v3 to Gitea v1 API translator")

# Configuration
GITEA_BASE_URL = os.getenv("GITEA_BASE_URL", "https://gitea.eco.tsi-dev.otc-service.com")
GITEA_API_TOKEN = os.getenv("GITEA_API_TOKEN", "")

# HTTP client with timeout
http_client = httpx.AsyncClient(timeout=30.0)


def translate_v3_to_v1_path(v3_path: str) -> str:
    """
    Translate GitHub API v3 paths to Gitea API v1 paths.

    GitHub v3: /api/v3/repos/{owner}/{repo}/branches/{branch}
    Gitea v1:  /api/v1/repos/{owner}/{repo}/branches/{branch}
    """
    # Remove /api/v3 prefix and add /api/v1
    if v3_path.startswith("/api/v3/"):
        v1_path = "/api/v1" + v3_path[7:]
    elif v3_path.startswith("/api/v3"):
        v1_path = "/api/v1" + v3_path[6:]
    elif v3_path.startswith("/"):
        v1_path = "/api/v1" + v3_path
    else:
        v1_path = "/api/v1/" + v3_path

    logger.debug(f"Path translation: {v3_path} -> {v1_path}")
    return v1_path


def translate_gitea_to_github_response(gitea_data: dict, endpoint_type: str) -> dict:
    """
    Translate Gitea API v1 response format to GitHub API v3 format.
    """
    if endpoint_type == "meta":
        # GitHub meta endpoint expects specific fields
        # Gitea /version returns: {"version": "1.24.0"}
        return {
            "verifiable_password_authentication": True,
            "installed_version": gitea_data.get("version", "unknown"),
            "github_services_sha": "unknown"
        }

    # For most endpoints, the structure is similar enough
    return gitea_data


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "service": "gitea-api-adapter"}


@app.get("/api/v3/meta")
async def get_meta():
    """
    GitHub /meta endpoint - returns GitHub Enterprise metadata.
    Translates to Gitea /version endpoint.
    """
    logger.info("Handling /api/v3/meta request")

    try:
        gitea_url = f"{GITEA_BASE_URL}/api/v1/version"
        headers = {}
        if GITEA_API_TOKEN:
            headers["Authorization"] = f"token {GITEA_API_TOKEN}"

        logger.debug(f"Fetching from Gitea: {gitea_url}")
        response = await http_client.get(gitea_url, headers=headers)

        if response.status_code == 200:
            gitea_data = response.json()
            github_response = translate_gitea_to_github_response(gitea_data, "meta")
            logger.info(f"Returning translated meta response: {github_response}")
            return github_response
        else:
            logger.error(f"Gitea returned status {response.status_code}: {response.text}")
            raise HTTPException(status_code=response.status_code, detail=response.text)

    except httpx.RequestError as e:
        logger.error(f"Error connecting to Gitea: {e}")
        raise HTTPException(status_code=502, detail=f"Error connecting to Gitea: {str(e)}")


@app.api_route("/repos/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"])
async def proxy_repos_request(path: str, request: Request):
    """
    Proxy for GitHub API requests starting with /repos/.
    This handles the standard GitHub API format (api.github.com/repos/...).
    Translates to Gitea API v1 paths.
    """
    logger.info(f"Proxying {request.method} request: /repos/{path}")

    # Translate path - add /api/v1/repos/ prefix for Gitea
    v1_path = f"/api/v1/repos/{path}"
    gitea_url = f"{GITEA_BASE_URL}{v1_path}"

    # Prepare headers
    headers = {}
    if GITEA_API_TOKEN:
        headers["Authorization"] = f"token {GITEA_API_TOKEN}"

    # Copy relevant headers from original request
    for header in ["Content-Type", "Accept"]:
        if header.lower() in request.headers:
            headers[header] = request.headers[header.lower()]

    # Get query parameters
    query_params = dict(request.query_params)

    # Get request body if present
    body = None
    if request.method in ["POST", "PUT", "PATCH"]:
        body = await request.body()

    try:
        logger.debug(f"Forwarding to Gitea: {request.method} {gitea_url}")
        logger.debug(f"Headers: {headers}")
        logger.debug(f"Query params: {query_params}")

        # Forward request to Gitea
        gitea_response = await http_client.request(
            method=request.method,
            url=gitea_url,
            headers=headers,
            params=query_params,
            content=body
        )

        logger.info(f"Gitea response: {gitea_response.status_code}")

        # Return Gitea response (most endpoints have compatible structure)
        return Response(
            content=gitea_response.content,
            status_code=gitea_response.status_code,
            headers=dict(gitea_response.headers),
            media_type=gitea_response.headers.get("content-type", "application/json")
        )

    except httpx.RequestError as e:
        logger.error(f"Error connecting to Gitea: {e}")
        raise HTTPException(status_code=502, detail=f"Error connecting to Gitea: {str(e)}")


@app.api_route("/api/v3/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"])
async def proxy_api_v3_request(path: str, request: Request):
    """
    Generic proxy for GitHub API v3 requests with /api/v3/ prefix.
    This handles GitHub Enterprise format paths.
    Translates v3 paths to v1 and forwards to Gitea.
    """
    logger.info(f"Proxying {request.method} request: /api/v3/{path}")

    # Translate path
    v1_path = translate_v3_to_v1_path(f"/api/v3/{path}")
    gitea_url = f"{GITEA_BASE_URL}{v1_path}"

    # Prepare headers
    headers = {}
    if GITEA_API_TOKEN:
        headers["Authorization"] = f"token {GITEA_API_TOKEN}"

    # Copy relevant headers from original request
    for header in ["Content-Type", "Accept"]:
        if header.lower() in request.headers:
            headers[header] = request.headers[header.lower()]

    # Get query parameters
    query_params = dict(request.query_params)

    # Get request body if present
    body = None
    if request.method in ["POST", "PUT", "PATCH"]:
        body = await request.body()

    try:
        logger.debug(f"Forwarding to Gitea: {request.method} {gitea_url}")
        logger.debug(f"Headers: {headers}")
        logger.debug(f"Query params: {query_params}")

        # Forward request to Gitea
        gitea_response = await http_client.request(
            method=request.method,
            url=gitea_url,
            headers=headers,
            params=query_params,
            content=body
        )

        logger.info(f"Gitea response: {gitea_response.status_code}")

        # Return Gitea response (most endpoints have compatible structure)
        return Response(
            content=gitea_response.content,
            status_code=gitea_response.status_code,
            headers=dict(gitea_response.headers),
            media_type=gitea_response.headers.get("content-type", "application/json")
        )

    except httpx.RequestError as e:
        logger.error(f"Error connecting to Gitea: {e}")
        raise HTTPException(status_code=502, detail=f"Error connecting to Gitea: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)

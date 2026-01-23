"""
Mitmproxy addon to intelligently route GitHub API calls.

Routes:
- /app/* → api.github.com (GitHub App API - real GitHub)
- /repos/infra/* → gitea-api-adapter (Gitea repos)
- everything else → api.github.com (fallback)
"""
import re
from mitmproxy import http


# Gitea organization/users that should be routed to gitea-api-adapter
GITEA_ORGS = ["infra"]

# Target for Gitea API calls
GITEA_API_ADAPTER = "gitea-api-adapter.zuul.svc.cluster.local"
REAL_GITHUB_API = "api.github.com"


class APIRouter:
    def request(self, flow: http.HTTPFlow) -> None:
        # Process requests to api.github.com and gitea.eco.tsi-dev.otc-service.com
        if flow.request.host not in [REAL_GITHUB_API, "gitea.eco.tsi-dev.otc-service.com"]:
            return

        path = flow.request.path
        
        # GitHub App API calls must go to real GitHub
        if path.startswith("/app/"):
            # Keep destination as api.github.com
            flow.request.host = REAL_GITHUB_API
            flow.request.port = 443
            return
        
        # GitHub Enterprise /meta endpoint - route to gitea-api-adapter
        # This is called by Zuul to detect GitHub Enterprise installation
        # GitHub API v3 uses /api/v3/meta path
        if path == "/meta" or path.startswith("/meta?") or path == "/api/v3/meta" or path.startswith("/api/v3/meta?"):
            flow.request.host = GITEA_API_ADAPTER
            flow.request.port = 443
            return
        
        # Check if this is a Gitea repository path
        # Pattern: /repos/{org}/{repo}/*
        repo_match = re.match(r'^/repos/([^/]+)/', path)
        if repo_match:
            org = repo_match.group(1)
            if org in GITEA_ORGS:
                # Route to gitea-api-adapter
                flow.request.host = GITEA_API_ADAPTER
                flow.request.port = 443
                # Keep the path as-is, gitea-api-adapter will translate
                return
        
        # All other requests go to real GitHub (default)
        # This includes /user, etc.
        pass


addons = [APIRouter()]

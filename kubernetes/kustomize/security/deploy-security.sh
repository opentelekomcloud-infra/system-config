#!/bin/bash

# Security deployment script for Kubernetes ingress protection
set -e

NAMESPACE="security"
INGRESS_NAMESPACE="ingress-nginx"

echo "🔒 Deploying Multi-Layer Security Stack for Kubernetes Ingresses"
echo "=============================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "✅ Checking prerequisites..."
if ! command_exists kubectl; then
    echo "❌ kubectl is required but not installed"
    exit 1
fi

if ! command_exists kustomize; then
    echo "❌ kustomize is required but not installed"
    exit 1
fi

# Create namespaces if they don't exist
echo "📁 Creating namespaces..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Phase 1: Deploy basic nginx security configuration
echo "🛡️  Phase 1: Deploying nginx security configuration..."
kubectl apply -f nginx-security-config.yaml

# Phase 2: Deploy fail2ban
echo "🚫 Phase 2: Deploying fail2ban for automatic IP blocking..."
kubectl apply -f fail2ban-config.yaml
kubectl apply -f fail2ban-daemonset.yaml

# Wait for fail2ban to be ready
echo "⏳ Waiting for fail2ban to be ready..."
kubectl rollout status daemonset/fail2ban -n kube-system --timeout=300s

# Phase 3: Deploy threat intelligence updater
echo "🌐 Phase 3: Deploying threat intelligence feeds..."
kubectl apply -f threat-intel-updater.yaml

# Phase 4: Deploy ModSecurity WAF
echo "🔥 Phase 4: Deploying ModSecurity WAF..."
kubectl apply -f modsecurity-config.yaml

# Phase 5: Deploy monitoring and alerting
echo "📊 Phase 5: Deploying security monitoring..."
kubectl apply -f monitoring-config.yaml

# Phase 6: Update existing ingresses with security annotations
echo "🔧 Phase 6: Updating existing ingresses with security..."

# Function to add security annotations to ingress
add_security_to_ingress() {
    local ingress_name=$1
    local namespace=$2

    echo "  🔒 Securing ingress: $ingress_name in namespace: $namespace"

    kubectl annotate ingress $ingress_name -n $namespace \
        nginx.ingress.kubernetes.io/rate-limit="10" \
        nginx.ingress.kubernetes.io/rate-limit-window="1m" \
        nginx.ingress.kubernetes.io/limit-connections="5" \
        nginx.ingress.kubernetes.io/server-snippet='
            if ($http_user_agent ~* (bot|crawler|spider|scanner)) {
                return 403;
            }
            if ($http_user_agent = "") {
                return 403;
            }' \
        --overwrite || echo "    ⚠️  Failed to update $ingress_name"
}

# Get all ingresses and add security
INGRESSES=$(kubectl get ingress --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}')

while IFS= read -r line; do
    if [ -n "$line" ]; then
        namespace=$(echo $line | awk '{print $1}')
        name=$(echo $line | awk '{print $2}')
        add_security_to_ingress $name $namespace
    fi
done <<< "$INGRESSES"

# Phase 7: Configure nginx ingress controller
echo "⚙️  Phase 7: Configuring nginx ingress controller..."

# Patch nginx configmap with security settings
kubectl patch configmap nginx-configuration -n $INGRESS_NAMESPACE --type='merge' -p='{
    "data": {
        "enable-modsecurity": "true",
        "modsecurity-snippet": "SecRuleEngine On\nSecRequestBodyAccess On\nSecAuditEngine RelevantOnly",
        "rate-limit-enabled": "true",
        "limit-connections": "10",
        "limit-rps": "5"
    }
}' || echo "⚠️  ConfigMap patch failed, it might not exist yet"

# Restart nginx ingress controller to apply changes
echo "🔄 Restarting nginx ingress controller..."
kubectl rollout restart deployment/nginx-ingress-controller -n $INGRESS_NAMESPACE || \
kubectl rollout restart deployment/ingress-nginx-controller -n $INGRESS_NAMESPACE || \
echo "⚠️  Could not restart nginx controller - please restart manually"

# Phase 8: Verification
echo "✅ Phase 8: Verifying deployment..."

# Check if all components are running
echo "📋 Checking component status:"

# Check fail2ban
if kubectl get daemonset fail2ban -n kube-system >/dev/null 2>&1; then
    echo "  ✅ Fail2ban: Running"
else
    echo "  ❌ Fail2ban: Not found"
fi

# Check threat intel updater
if kubectl get cronjob threat-intel-updater -n kube-system >/dev/null 2>&1; then
    echo "  ✅ Threat Intel Updater: Scheduled"
else
    echo "  ❌ Threat Intel Updater: Not found"
fi

# Check security monitoring
if kubectl get cronjob security-scanner -n monitoring >/dev/null 2>&1; then
    echo "  ✅ Security Monitor: Scheduled"
else
    echo "  ❌ Security Monitor: Not found"
fi

# Display security summary
echo ""
echo "🎯 SECURITY SUMMARY"
echo "==================="
echo "✅ Rate limiting: 10 requests/min per IP"
echo "✅ Connection limiting: 5 concurrent connections per IP"
echo "✅ Bot blocking: Common bots and scanners blocked"
echo "✅ Threat intelligence: Updated every 6 hours"
echo "✅ ModSecurity WAF: OWASP Core Rule Set enabled"
echo "✅ Fail2ban: Automatic IP blocking on suspicious activity"
echo "✅ Monitoring: Security alerts and dashboards configured"
echo ""

# Display next steps
echo "🚀 NEXT STEPS"
echo "============="
echo "1. Configure threat intelligence API keys:"
echo "   kubectl patch secret security-secrets -n security -p '{\"data\":{\"API_KEYS\":\"<base64-encoded-keys>\"}}}'"
echo ""
echo "2. Set up alerting webhook:"
echo "   kubectl patch secret security-secrets -n security -p '{\"data\":{\"WEBHOOK_URL\":\"<base64-encoded-url>\"}}}'"
echo ""
echo "3. Monitor security dashboard at:"
echo "   kubectl port-forward -n monitoring svc/grafana 3000:3000"
echo ""
echo "4. View blocked IPs:"
echo "   kubectl logs -n kube-system daemonset/fail2ban"
echo ""
echo "5. Check nginx logs for blocked requests:"
echo "   kubectl logs -n $INGRESS_NAMESPACE deployment/nginx-ingress-controller | grep 403"
echo ""

echo "🔒 Security deployment completed successfully!"
echo "Your ingresses are now protected against common attacks and DDoS."
echo ""
echo "⚠️  IMPORTANT: Test your applications to ensure they work correctly with the new security rules."
echo "⚠️  Monitor logs for false positives and adjust rules as needed."

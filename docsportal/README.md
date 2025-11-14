# Docsportal kustomize app

Docsportal is an nginx based deployment with certain configuration inside. It
is required since capabilities of a regular ingress are in a lot of cases not
sufficient.

Deployment of few apps into single namespace is not recommended, since ingress
does not support (as of now) dynamic selectors.

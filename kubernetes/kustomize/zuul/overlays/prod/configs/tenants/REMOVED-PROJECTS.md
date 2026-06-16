# Projects Removed from eco2 Tenant

These projects were temporarily removed from
`kubernetes/kustomize/zuul/overlays/prod/configs/tenants/main.yaml`
during the migration to the new prod Zuul (otcinfra2 / `eco2` tenant).

## Why they were removed

When the GitHub App `otc-zuul-prod` cannot resolve an installation for a
project, or when GraphQL `branch-protection` returns 403, GitHub puts
`X-RateLimit-Remaining: 0` in the 403 response headers. Zuul's
`GithubRateLimitHandler` mis-interprets this as a real rate-limit and
sleeps for ~3389 seconds, holding the tenant read-lock and **wedging the
entire tenant load** for ~1 hour.

To unblock initial bring-up of the new prod scheduler, the projects below
were dropped from the tenant config. They must be re-added once the root
cause for each is fixed.

## Removed projects

| Project | Removed in commit | Reason | How to re-add |
|---------|-------------------|--------|---------------|
| `ansible/ansible` | `46cbf7e9` | Not an OTC repo. The GitHub App cannot be installed on the upstream `ansible` org. Was a leftover from the old config. | Likely should stay removed unless we mirror it locally. |
| `opentelekomcloud-infra/ansible-role-apimon` | `18ed22db` | GraphQL `branch-protection` returned 403 even though the App is installed on `opentelekomcloud-infra`. Suspected missing App permission `administration:read`, or repo-level access restriction. | Verify App permissions at https://github.com/organizations/opentelekomcloud-infra/settings/installations/125659366 — ensure `Administration: Read-only` is granted. Then re-add the entry. |
| `opentelekomcloud-infra/grafana-docs-monitoring` | `18ed22db` | Same as above. | Same as above. |
| `opentelekomcloud-infra/mCaptcha` | `18ed22db` | Same as above. | Same as above. |
| `terraform-opentelekomcloud-modules/terraform-opentelekomcloud-vpc` | `1239f303` | GitHub App `otc-zuul-prod` is not installed on the `terraform-opentelekomcloud-modules` org. | Install the App on the org via https://github.com/apps/otc-zuul-prod/installations/new — select `terraform-opentelekomcloud-modules` and grant access to all repos. Then re-add the entry. |

## YAML snippets to restore

```yaml
          - opentelekomcloud-infra/ansible-role-apimon:
              include:
                - project
          - opentelekomcloud-infra/grafana-docs-monitoring:
              include:
                - project
          - opentelekomcloud-infra/mCaptcha:
              include:
                - project
          - terraform-opentelekomcloud-modules/terraform-opentelekomcloud-vpc:
              include:
                - project
```

(All four belong in the `github:` → `untrusted-projects:` list, sorted
alphabetically by `<org>/<repo>`.)

## Validation after re-adding

After re-adding any project:

1. Commit + push; wait for ArgoCD to sync the CM.
2. Restart the scheduler:
   `kubectl -n zuul-ci rollout restart deploy/zuul-scheduler`
3. Watch logs for the project name; expect `Got branches for <org>/<repo>`
   without any `API rate limit reached` warnings.
4. Confirm the project appears in `/api/tenant/eco2/projects`.

If `API rate limit reached` re-appears immediately for that project, the
underlying GitHub App permission issue is **not** fixed — remove again
and continue investigation.

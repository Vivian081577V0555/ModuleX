# ModuleX Project Notes

## Infrastructure

- The production host is the AWS Lightsail instance at `3.34.50.251`.
- Public DNS for `modules-x.com` is managed in the Lightsail console under
  `Domains & DNS > modules-x.com > DNS records`.
- Do not add application subdomains to the similarly named Route 53 hosted
  zone; that zone is not delegated for public `modules-x.com` traffic.
- Active Docker Compose sites:
  - `modulex-demo` -> host port `8080`
  - `builder-hc` -> host port `8082`
  - `enterprise-demo` -> host port `8084`
- Nginx on the Lightsail host terminates HTTPS and proxies each subdomain to
  its corresponding local Docker port.

## ASPICE Demo

- The ASPICE demo runs at `https://enterprise-demo.modules-x.com`.
- Requirements and verification are intentionally separated into the
  `aspice-requirements` and `aspice-verification` Redmine projects.
- Their issue trees are available at:
  - `/projects/aspice-requirements/issues_trees/tree_index`
  - `/projects/aspice-verification/issues_trees/tree_index`
  - `/projects/aspice-demo/wiki/ASPICE_Dashboard`
  - Project issue pages default to the issue-tree view. The requirements project has public CReq, SYS, SWR, and SWU saved queries; the verification project has public SYS.4, SYS.5, SWE.4, SWE.5, and SWE.6 saved queries.
- Cross-project Redmine issue relations provide bidirectional traceability.
  Stable `Trace ID` custom-field values are used for imports and audit output.
- Five golden paths and their configuration are maintained by
  `aspice-demo/seed_redmine.rb`. The script is idempotent.
- Software Unit issues link to source artifacts under `aspice-demo/src/` at
  immutable Git commit `736f3801e02d2a993b509684c405654892261da0`.

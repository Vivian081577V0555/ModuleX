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
- The ASPICE dashboard uses the `{{aspice_dashboard}}` macro from
  `redmine_aspice_dashboard`; its charts and matrix are calculated live from
  Redmine issues and do not depend on Metabase.
- Cross-project Redmine issue relations provide bidirectional traceability.
  Stable `Trace ID` custom-field values are used for imports and audit output.
- Five golden paths and their configuration are maintained by
  `aspice-demo/seed_redmine.rb`. The script is idempotent.
- `aspice-demo/enrich_test_cases.rb` adds execution-ready steps, acceptance
  criteria, evidence rules, and two clearly labelled simulated PNG assets to
  each of the 25 verification test cases without changing their verdicts.
- Controlled ASPICE documents are managed from
  `/projects/aspice-requirements/document-control`. The approval page mirrors
  DMSF's two-level folder hierarchy and keeps root-level documents separate.
  The approval path is
  Technical Review, ASPICE QA Review, then Document Control Release; approved
  revisions remain locked.
- `aspice-demo/verify_document_control.rb` creates at most one clearly named
  demo document and verifies all three approvals and the final lock.
- The DMSF root `ISO 26262 - 48V Auxiliary Battery Safety` contains the
  project-start document framework: 10 lifecycle folders, 36 editable
  templates, and 6 Redmine milestones. It is created idempotently by
  `aspice-demo/seed_iso26262_documents.rb`.
- The DMSF root `Automotive SPICE 4.0 - Project Work Products` contains 40
  project-start templates across MAN.3, SYS.1-5, SWE.1-6, HWE.1-4,
  SUP.1/8/9/10, ACQ.4, and CL2/CL3 evidence. It is created idempotently by
  `aspice-demo/seed_aspice_documents.rb` together with 7 project milestones.
- `ISO26262_Automotive_SPICE_Work_Product_Crosswalk.md` is a root-level DMSF
  document beside both framework folders. Its 37-row reuse and relationship
  table is created idempotently by
  `aspice-demo/seed_iso26262_aspice_crosswalk.rb`.
- Software Unit issues link to source artifacts under `aspice-demo/src/` at
  immutable Git commit `736f3801e02d2a993b509684c405654892261da0`.

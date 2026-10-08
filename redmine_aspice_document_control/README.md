# ASPICE Document Control

A focused approval UI backed by the existing Redmine DMSF plugin. It is
available at `/projects/:project_id/document-control`.

The plugin deliberately keeps the workflow small: upload in DMSF, assign and
submit, then approve or return from a single project page. Workflow definitions,
revision history, locking, and audit actions remain owned by DMSF. Documents
are grouped by the same two-level folder hierarchy as Document Manager.

## Installation

After copying the plugin, ensure directories are mode `755` and files are mode
`644`, then restart Redmine:

```sh
find redmine_aspice_document_control -type d -exec chmod 755 {} \;
find redmine_aspice_document_control -type f -exec chmod 644 {} \;
```

Run `aspice-demo/seed_redmine.rb` inside Redmine after DMSF migrations are
available. The seed creates the controlled-document folder, three-stage
workflow, reviewer groups, permissions, and demo accounts. Account passwords
are generated at deployment time unless supplied through environment variables.

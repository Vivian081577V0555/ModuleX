# ASPICE Document Control

A focused approval UI backed by the existing Redmine DMSF plugin.

The plugin deliberately keeps the workflow small: upload in DMSF, submit once,
then approve or return from a single project page. Workflow definitions,
revision history, locking, and audit actions remain owned by DMSF.

## Integration patch

Copy `patches/dmsf_show.html.erb` over
`redmine_dmsf/app/views/dmsf/show.html.erb`. The upstream view contains only a
single render call; this patch preserves that behavior unless
`document_control=1` is present.

After copying the plugin, ensure directories are mode `755` and files are mode
`644`, apply the integration patch, and restart Redmine:

```sh
find redmine_aspice_document_control -type d -exec chmod 755 {} \;
find redmine_aspice_document_control -type f -exec chmod 644 {} \;
cp redmine_aspice_document_control/patches/dmsf_show.html.erb \
  redmine_dmsf/app/views/dmsf/show.html.erb
```

Run `aspice-demo/seed_redmine.rb` inside Redmine after DMSF migrations are
available. The seed creates the controlled-document folder, three-stage
workflow, reviewer groups, permissions, and demo accounts. Account passwords
are generated at deployment time unless supplied through environment variables.

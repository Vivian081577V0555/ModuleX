# ModuleX portability notes

This package is the patched version deployed and verified on the ModuleX Redmine server.

## Compatibility fixes

- Query Redmine custom-field STI types by class name strings for Rails 6 compatibility.
- Render project assignments with explicit checkbox IDs and labels while preserving project-tree indentation.
- Preserve scheduled time, mail templates, and project assignment parameters during create and update.

## Installation

1. Extract `redmine_custom_reminder` into the target Redmine `plugins` directory.
2. Run `bundle install` from the Redmine root.
3. Run `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`.
4. Restart Redmine.
5. Schedule `CustomRemindersJob.perform_now` periodically. A five-minute interval is recommended so each reminder's `scheduled_time` is honored.

SMTP delivery is configured by Redmine itself and is not included in this plugin package.

The reminder script fields execute Ruby code and should remain restricted to trusted administrators.

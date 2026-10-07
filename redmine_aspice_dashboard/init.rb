# frozen_string_literal: true

require_relative "lib/aspice_dashboard/snapshot"

Redmine::Plugin.register :redmine_aspice_dashboard do
  name "ASPICE Live Dashboard"
  author "ModuleX"
  description "Live ASPICE traceability metrics rendered from Redmine issues."
  version "0.1.0"
  requires_redmine version_or_higher: "5.0.0"
end

Redmine::WikiFormatting::Macros.register do
  desc "Render the live ASPICE traceability dashboard"
  macro :aspice_dashboard do |_object, _args|
    render partial: "aspice_dashboard/dashboard",
           locals: { dashboard: AspiceDashboard::Snapshot.new }
  end
end

# frozen_string_literal: true

Redmine::Plugin.register :redmine_aspice_document_control do
  name "ASPICE Document Control"
  author "ModuleX"
  description "A focused approval surface backed by Redmine DMSF."
  version "0.1.0"

  requires_redmine version_or_higher: "5.0.0"

  project_module :aspice_document_control do
    permission :view_aspice_document_control, { aspice_document_control: [:index] }, read: true
    permission :submit_aspice_documents, { aspice_document_control: [:index] }
    permission :approve_aspice_documents, { aspice_document_control: [:index] }
  end

  menu :project_menu,
       :aspice_document_control,
       { controller: "aspice_document_control", action: "index" },
       caption: "Document Control",
       after: :dmsf,
       param: :project_id
end

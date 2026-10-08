# frozen_string_literal: true

get "projects/:project_id/document-control",
    to: "aspice_document_control#index",
    as: :project_aspice_document_control

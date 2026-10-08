# frozen_string_literal: true

class AspiceDocumentControlController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize

  helper :aspice_document_control

  def index
    @filter = params[:filter].presence || "all"
    @files = DmsfFile.where(project_id: @project.id, deleted: DmsfFile::STATUS_ACTIVE)
                     .includes(:dmsf_folder, :dmsf_file_revisions)
                     .order(updated_at: :desc)
                     .select do |file|
      helpers.visible_for_document_control_filter?(file.last_revision, @filter)
    end

    files_by_folder = @files.group_by(&:dmsf_folder_id)
    @root_files = files_by_folder[nil] || []
    folders = DmsfFolder.where(project_id: @project.id, deleted: false).order(:title).to_a
    root_folders = folders.select { |folder| folder.dmsf_folder_id.nil? }
    children_by_parent = folders.reject { |folder| folder.dmsf_folder_id.nil? }.group_by(&:dmsf_folder_id)

    @folder_sections = root_folders.filter_map do |root|
      children = (children_by_parent[root.id] || []).filter_map do |child|
        child_files = files_by_folder[child.id] || []
        { folder: child, files: child_files } if child_files.any?
      end
      root_files = files_by_folder[root.id] || []
      next if root_files.empty? && children.empty?

      { folder: root, files: root_files, children: children }
    end
  end
end

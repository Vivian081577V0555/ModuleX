# frozen_string_literal: true

# Run with: bundle exec rails runner /path/to/verify_document_control.rb RAILS_ENV=production
require "digest"
require "fileutils"

project = Project.find_by!(identifier: "aspice-requirements")
folder = DmsfFolder.find_by!(project_id: project.id, title: "ASPICE Controlled Documents")
workflow = DmsfWorkflow.find_by!(project_id: project.id, name: "ASPICE Controlled Document Approval")
author = User.find_by!(login: "aspice.author")
filename = "ASPICE_Document_Approval_Demo.txt"
content = <<~TEXT
  ASPICE Controlled Document Approval Demo

  This controlled sample verifies the Technical Review, ASPICE QA Review,
  and Document Control Release stages in ModuleX.
TEXT

file = DmsfFile.find_by(project_id: project.id, dmsf_folder_id: folder.id, name: filename)

unless file
  User.current = author
  file = DmsfFile.create!(
    project: project,
    dmsf_folder: folder,
    name: filename,
    deleted: DmsfFile::STATUS_ACTIVE
  )
  revision = DmsfFileRevision.new(
    dmsf_file: file,
    name: filename,
    title: "ASPICE Document Approval Demo",
    description: "End-to-end approval demonstration document.",
    major_version: 1,
    minor_version: 0,
    size: content.bytesize,
    mime_type: "text/plain",
    digest: Digest::MD5.hexdigest(content),
    deleted: DmsfFileRevision::STATUS_ACTIVE,
    user: author
  )
  revision.disk_filename = revision.new_storage_filename
  revision.save!
  FileUtils.mkdir_p(File.dirname(revision.disk_file(search_if_not_exists: false)))
  File.binwrite(revision.disk_file(search_if_not_exists: false), content)

  revision.set_workflow(workflow.id, "start")
  revision.save!
  revision.assign_workflow(workflow.id)
  file.lock!
else
  revision = file.last_revision
end

if revision.workflow == DmsfWorkflow::STATE_WAITING_FOR_APPROVAL
  %w[aspice.techreview aspice.qa aspice.doccontrol].each do |login|
    approver = User.find_by!(login: login)
    User.current = approver
    assignment = workflow.next_assignments(revision.id).find { |item| item.user_id == approver.id }
    raise "No current assignment for #{login}" unless assignment

    action = DmsfWorkflowStepAction.create!(
      dmsf_workflow_step_assignment: assignment,
      action: DmsfWorkflowStepAction::ACTION_APPROVE,
      note: "Approved during the ModuleX document-control verification."
    )
    workflow.try_finish(revision, action, nil)
    revision.reload
  end
end

approval_count = DmsfWorkflowStepAction
                 .joins(:dmsf_workflow_step_assignment)
                 .where(
                   dmsf_workflow_step_assignments: { dmsf_file_revision_id: revision.id },
                   action: DmsfWorkflowStepAction::ACTION_APPROVE
                 ).count

raise "Document did not reach Approved" unless revision.workflow == DmsfWorkflow::STATE_APPROVED
raise "Expected 3 approvals, got #{approval_count}" unless approval_count == 3
raise "Approved document is not locked" unless file.reload.locked?

puts "DOCUMENT=#{file.name}"
puts "VERSION=#{revision.version}"
puts "WORKFLOW=#{workflow.name}"
puts "APPROVALS=#{approval_count}"
puts "STATUS=Approved"
puts "LOCKED=true"

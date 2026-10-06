# frozen_string_literal: true

module AspiceDocumentControlHelper
  WORKFLOW_NAME = "ASPICE Controlled Document Approval"

  def document_control_workflow
    DmsfWorkflow.active.find_by(project_id: @project.id, name: WORKFLOW_NAME)
  end

  def document_control_pending_assignments(revision)
    workflow = DmsfWorkflow.find_by(id: revision&.dmsf_workflow_id)
    return [] unless workflow && revision.workflow == DmsfWorkflow::STATE_WAITING_FOR_APPROVAL

    workflow.next_assignments(revision.id)
  end

  def document_control_actionable?(revision)
    document_control_pending_assignments(revision).any? { |assignment| assignment.user_id == User.current.id }
  end

  def document_control_assignment(revision)
    document_control_pending_assignments(revision).find { |assignment| assignment.user_id == User.current.id }
  end

  def document_control_step(revision)
    document_control_pending_assignments(revision).first&.dmsf_workflow_step&.name || "-"
  end

  def document_control_approvers(revision)
    names = document_control_pending_assignments(revision).filter_map(&:user).map(&:name).uniq
    names.presence&.join(", ") || "-"
  end

  def document_control_status(revision)
    return "Draft" unless revision

    case revision.workflow
    when DmsfWorkflow::STATE_WAITING_FOR_APPROVAL then "In Approval"
    when DmsfWorkflow::STATE_APPROVED then "Approved"
    when DmsfWorkflow::STATE_REJECTED then "Returned"
    when DmsfWorkflow::STATE_OBSOLETE then "Obsolete"
    else "Draft"
    end
  end

  def visible_for_document_control_filter?(revision, filter)
    case filter
    when "mine" then document_control_actionable?(revision)
    when "approval" then revision&.workflow == DmsfWorkflow::STATE_WAITING_FOR_APPROVAL
    when "approved" then revision&.workflow == DmsfWorkflow::STATE_APPROVED
    when "returned" then revision&.workflow == DmsfWorkflow::STATE_REJECTED
    when "draft"
      (revision.nil? || revision.workflow.blank? || revision.workflow.to_i.zero?) &&
        revision&.user_id == User.current.id
    else true
    end
  end
end

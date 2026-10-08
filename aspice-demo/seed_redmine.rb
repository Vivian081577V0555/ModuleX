# frozen_string_literal: true

# Run inside the Redmine container with:
#   bundle exec rails runner /tmp/seed_redmine.rb

require "securerandom"

SOURCE_COMMIT = ENV.fetch("ASOURCE_COMMIT", "736f3801e02d2a993b509684c405654892261da0")
SOURCE_REPOSITORY = "https://github.com/Vivian081577V0555/ModuleX"

# Seeding is an administrative bootstrap operation, not a user-authored batch.
ActionMailer::Base.perform_deliveries = false

ActiveRecord::Base.transaction do
admin = User.find_by(admin: true) || User.find_by(login: "admin")
raise "An administrator account is required" unless admin

# Requirement and verification work products live in separate projects. Keep
# their trees independent while allowing explicit cross-project trace links.
Setting.cross_project_issue_relations = "1"
Setting.issue_group_assignment = "1"
Setting.plugin_redmine_issues_tree = Setting.plugin_redmine_issues_tree.to_h.merge(
  "default_redirect_to_tree_view" => "true",
  "default_redirect_to_tree_view_without_project" => "false"
)

default_status = IssueStatus.where(is_closed: false).order(:position).first
resolved_status = IssueStatus.find_by(name: "已解決") || default_status
default_priority = IssuePriority.default || IssuePriority.order(:position).first

def ensure_project(identifier:, name:, description:, parent: nil)
  project = Project.find_or_initialize_by(identifier: identifier)
  project.name = name
  project.description = description
  project.parent = parent
  project.is_public = false
  project.status = Project::STATUS_ACTIVE
  project.enabled_module_names = %w[issue_tracking wiki files calendar gantt]
  project.save!
  project
end

root_project = ensure_project(
  identifier: "aspice-demo",
  name: "ASPICE Traceability Demo",
  description: "Umbrella project for the separated requirement and verification teams."
)

requirements_project = ensure_project(
  identifier: "aspice-requirements",
  name: "ASPICE Requirements",
  description: "Customer, system, software requirement, and software unit work products.",
  parent: root_project
)

verification_project = ensure_project(
  identifier: "aspice-verification",
  name: "ASPICE Verification",
  description: "SYS.4, SYS.5, SWE.4, SWE.5, and SWE.6 verification work products.",
  parent: root_project
)

requirements_project.enabled_module_names = (
  requirements_project.enabled_module_names + %w[dmsf aspice_document_control]
).uniq

def ensure_tracker(name, description, default_status)
  tracker = Tracker.find_or_initialize_by(name: name)
  tracker.description = description
  tracker.default_status = default_status
  tracker.is_in_roadmap = false
  tracker.save!
  tracker
end

trackers = {
  requirement_group: ensure_tracker("Requirement Trace Group", "Container for one requirement golden path.", default_status),
  customer_requirement: ensure_tracker("Customer Requirement", "Customer or stakeholder requirement.", default_status),
  system_requirement: ensure_tracker("System Requirement", "ASPICE SYS.2 system requirement.", default_status),
  software_requirement: ensure_tracker("Software Requirement", "ASPICE SWE.1 software requirement.", default_status),
  software_unit: ensure_tracker("Software Unit", "ASPICE SWE.3 software unit linked to immutable source.", default_status),
  verification_group: ensure_tracker("Verification Trace Group", "Container for one verification golden path.", default_status),
  sys4: ensure_tracker("SYS.4 Verification", "System integration and integration verification.", default_status),
  sys5: ensure_tracker("SYS.5 Verification", "System verification.", default_status),
  swe4: ensure_tracker("SWE.4 Verification", "Software unit verification.", default_status),
  swe5: ensure_tracker("SWE.5 Verification", "Software component and integration verification.", default_status),
  swe6: ensure_tracker("SWE.6 Verification", "Integrated software verification.", default_status)
}

requirement_trackers = trackers.values_at(
  :requirement_group, :customer_requirement, :system_requirement,
  :software_requirement, :software_unit
)
verification_trackers = trackers.values_at(
  :verification_group, :sys4, :sys5, :swe4, :swe5, :swe6
)
requirements_project.trackers = requirement_trackers
verification_project.trackers = verification_trackers

def ensure_public_tracker_query(project:, admin:, name:, tracker:)
  query = IssueQuery.find_or_initialize_by(project: project, name: name)
  query.user = admin
  query.visibility = Query::VISIBILITY_PUBLIC
  query.filters = {
    "status_id" => { operator: "*", values: [""] },
    "tracker_id" => { operator: "=", values: [tracker.id.to_s] }
  }
  query.column_names = %i[tracker status priority subject assigned_to updated_on]
  query.sort_criteria = [["subject", "asc"], ["id", "desc"]]
  query.group_by = nil
  query.save!
  query
end

{
  "CReq - Customer Requirements" => trackers[:customer_requirement],
  "SYS - System Requirements" => trackers[:system_requirement],
  "SWR - Software Requirements" => trackers[:software_requirement],
  "SWU - Software Units" => trackers[:software_unit]
}.each do |name, tracker|
  ensure_public_tracker_query(project: requirements_project, admin: admin, name: name, tracker: tracker)
end

{
  "SYS.4 - Integration Verification" => trackers[:sys4],
  "SYS.5 - System Verification" => trackers[:sys5],
  "SWE.4 - Unit Verification" => trackers[:swe4],
  "SWE.5 - Integration Verification" => trackers[:swe5],
  "SWE.6 - Software Verification" => trackers[:swe6]
}.each do |name, tracker|
  ensure_public_tracker_query(project: verification_project, admin: admin, name: name, tracker: tracker)
end

developer_permissions = Role.find_by(name: "開發人員")&.permissions || []
observer_permissions = %i[
  view_issues view_private_notes save_queries view_gantt view_calendar
  view_wiki_pages view_wiki_edits view_files browse_repository
]

def ensure_role(name, permissions)
  role = Role.find_or_initialize_by(name: name)
  role.permissions = permissions
  role.issues_visibility = "all"
  role.users_visibility = "all"
  role.time_entries_visibility = "all"
  role.assignable = true
  role.save!
  role
end

roles = {
  requirement_author: ensure_role("ASPICE Requirement Author", developer_permissions),
  technical_reviewer: ensure_role("ASPICE Technical Reviewer", observer_permissions),
  verification_engineer: ensure_role("ASPICE Verification Engineer", developer_permissions),
  process_qa: ensure_role("ASPICE Process QA", developer_permissions),
  observer: ensure_role("ASPICE Observer", observer_permissions),
  document_controller: ensure_role("ASPICE Document Controller", observer_permissions)
}

dmsf_read_permissions = %i[
  view_dmsf_file_revision_accesses view_dmsf_file_revisions
  view_dmsf_folders view_dmsf_files view_aspice_document_control
]
roles[:requirement_author].permissions |= dmsf_read_permissions + %i[
  file_manipulation folder_manipulation file_approval submit_aspice_documents
]
roles[:technical_reviewer].permissions |= dmsf_read_permissions + %i[
  file_approval approve_aspice_documents
]
roles[:process_qa].permissions |= dmsf_read_permissions + %i[
  file_approval approve_aspice_documents
]
roles[:document_controller].permissions |= dmsf_read_permissions + %i[
  file_approval approve_aspice_documents force_file_unlock manage_workflows
]
roles.values.each(&:save!)

def ensure_group(name)
  group = Group.find_or_initialize_by(lastname: name)
  group.save!
  group
end

groups = {
  requirements: ensure_group("ASPICE Requirement Team"),
  verification: ensure_group("ASPICE Verification Team"),
  process_qa: ensure_group("ASPICE Process QA Team"),
  technical_review: ensure_group("ASPICE Technical Review Team"),
  document_control: ensure_group("ASPICE Document Control Team"),
  sys4: ensure_group("ASPICE SYS.4 Team"),
  sys5: ensure_group("ASPICE SYS.5 Team"),
  swe4: ensure_group("ASPICE SWE.4 Team"),
  swe5: ensure_group("ASPICE SWE.5 Team"),
  swe6: ensure_group("ASPICE SWE.6 Team")
}

def ensure_demo_user(login:, firstname:, lastname:, mail:, password_env:)
  user = User.find_or_initialize_by(login: login)
  if user.new_record?
    password = ENV[password_env].presence || SecureRandom.base58(24)
    user.password = password
    user.password_confirmation = password
  end
  user.firstname = firstname
  user.lastname = lastname
  user.mail = mail
  user.status = User::STATUS_ACTIVE
  user.language = "en"
  user.must_change_passwd = false if user.respond_to?(:must_change_passwd=)
  user.save!
  user
end

demo_users = {
  author: ensure_demo_user(
    login: "aspice.author", firstname: "ASPICE", lastname: "Document Author",
    mail: "aspice.author@example.invalid", password_env: "ASPICE_AUTHOR_PASSWORD"
  ),
  technical_reviewer: ensure_demo_user(
    login: "aspice.techreview", firstname: "Technical", lastname: "Reviewer",
    mail: "aspice.techreview@example.invalid", password_env: "ASPICE_TECH_REVIEWER_PASSWORD"
  ),
  process_qa: ensure_demo_user(
    login: "aspice.qa", firstname: "ASPICE", lastname: "Process QA",
    mail: "aspice.qa@example.invalid", password_env: "ASPICE_QA_PASSWORD"
  ),
  document_controller: ensure_demo_user(
    login: "aspice.doccontrol", firstname: "Document", lastname: "Controller",
    mail: "aspice.doccontrol@example.invalid", password_env: "ASPICE_DOCUMENT_CONTROL_PASSWORD"
  )
}

{
  requirements: demo_users[:author],
  technical_review: demo_users[:technical_reviewer],
  process_qa: demo_users[:process_qa],
  document_control: demo_users[:document_controller]
}.each do |group_key, user|
  group = groups.fetch(group_key)
  group.users << user unless group.users.exists?(user.id)
end

def ensure_membership(project, principal, role)
  member = Member.find_or_initialize_by(project: project, principal: principal)
  member.roles = (member.roles + [role]).uniq
  member.save!
end

ensure_membership(requirements_project, groups[:requirements], roles[:requirement_author])
ensure_membership(requirements_project, groups[:technical_review], roles[:technical_reviewer])
ensure_membership(requirements_project, groups[:document_control], roles[:document_controller])
ensure_membership(verification_project, groups[:requirements], roles[:observer])
ensure_membership(requirements_project, groups[:verification], roles[:observer])
ensure_membership(verification_project, groups[:verification], roles[:verification_engineer])
ensure_membership(requirements_project, groups[:process_qa], roles[:process_qa])
ensure_membership(verification_project, groups[:process_qa], roles[:process_qa])
groups.values_at(:sys4, :sys5, :swe4, :swe5, :swe6).each do |group|
  ensure_membership(requirements_project, group, roles[:observer])
  ensure_membership(verification_project, group, roles[:verification_engineer])
end

controlled_folder = DmsfFolder.find_or_initialize_by(
  project_id: requirements_project.id,
  dmsf_folder_id: nil,
  title: "ASPICE Controlled Documents"
)
controlled_folder.description = "Working and released ASPICE documents. Use Document Control views to filter by status."
controlled_folder.notification = false
controlled_folder.user_id = admin.id
controlled_folder.deleted = false
controlled_folder.save!

approval_workflow = DmsfWorkflow.find_or_initialize_by(
  project_id: requirements_project.id,
  name: "ASPICE Controlled Document Approval"
)
approval_workflow.author = admin
approval_workflow.status = DmsfWorkflow::STATUS_ACTIVE
approval_workflow.save!

approval_steps = [
  [1, "Technical Review", demo_users[:technical_reviewer]],
  [2, "ASPICE QA Review", demo_users[:process_qa]],
  [3, "Document Control Release", demo_users[:document_controller]]
]
approval_steps.each do |step_number, step_name, approver|
  step = DmsfWorkflowStep.find_or_initialize_by(
    dmsf_workflow_id: approval_workflow.id,
    step: step_number
  )
  step.name = step_name
  step.user = approver
  step.operator = DmsfWorkflowStep::OPERATOR_OR
  step.save!
end

Setting.plugin_redmine_dmsf = Setting.plugin_redmine_dmsf.to_h.merge(
  "dmsf_keep_documents_locked" => "1",
  "only_approval_zero_minor_version" => "0"
)

def ensure_custom_field(name:, format:, trackers:, projects:, description:, possible_values: nil, required: false)
  field = IssueCustomField.find_or_initialize_by(name: name)
  field.field_format = format
  field.description = description
  field.is_required = required
  field.is_for_all = false
  field.is_filter = true
  field.searchable = true
  field.visible = true
  field.editable = true
  field.multiple = false
  field.possible_values = possible_values if possible_values
  field.trackers = trackers
  field.projects = projects
  field.save!
  field
end

all_trackers = trackers.values
all_projects = [requirements_project, verification_project]
path_values = [
  "GP-01 RSOC LED indication",
  "GP-02 over-voltage protection",
  "GP-03 charging mode threshold",
  "GP-04 UART supervision",
  "GP-05 AFE SOC estimation"
]

fields = {
  trace_id: ensure_custom_field(
    name: "Trace ID", format: "string", trackers: all_trackers, projects: all_projects,
    description: "Stable identifier used outside this Redmine database.", required: true
  ),
  golden_path: ensure_custom_field(
    name: "Golden Path", format: "list", trackers: all_trackers, projects: all_projects,
    description: "Demo end-to-end traceability path.", possible_values: path_values
  ),
  aspice_process: ensure_custom_field(
    name: "ASPICE Process", format: "list", trackers: all_trackers, projects: all_projects,
    description: "ASPICE process represented by the work product.",
    possible_values: %w[CUSTOMER SYS.2 SWE.1 SWE.3 SYS.4 SYS.5 SWE.4 SWE.5 SWE.6]
  ),
  review_status: ensure_custom_field(
    name: "Review Status", format: "list", trackers: all_trackers, projects: all_projects,
    description: "Review disposition for the work product.",
    possible_values: ["Draft", "In Review", "Conditional Accept", "Approved", "Rejected"]
  ),
  baseline: ensure_custom_field(
    name: "Baseline", format: "string", trackers: all_trackers, projects: all_projects,
    description: "Configuration baseline or release identifier."
  ),
  verification_result: ensure_custom_field(
    name: "Verification Result", format: "list", trackers: verification_trackers, projects: [verification_project],
    description: "Latest verification verdict.",
    possible_values: ["Pass", "Fail", "Blocked", "Not Executed"]
  ),
  git_repository: ensure_custom_field(
    name: "Git Repository", format: "string", trackers: [trackers[:software_unit]], projects: [requirements_project],
    description: "Git repository URL containing the software unit."
  ),
  git_commit: ensure_custom_field(
    name: "Git Commit", format: "string", trackers: [trackers[:software_unit]], projects: [requirements_project],
    description: "Immutable source commit SHA."
  ),
  source_file: ensure_custom_field(
    name: "Source File", format: "string", trackers: [trackers[:software_unit]], projects: [requirements_project],
    description: "Repository-relative source file path."
  ),
  source_symbol: ensure_custom_field(
    name: "Source Symbol", format: "string", trackers: [trackers[:software_unit]], projects: [requirements_project],
    description: "Function, class, or symbol implemented by this unit."
  ),
  source_url: ensure_custom_field(
    name: "Source URL", format: "link", trackers: [trackers[:software_unit]], projects: [requirements_project],
    description: "Direct link to the file at the recorded Git commit."
  )
}

# Demo roles may move work products through all configured states. Field-level
# permissions remain governed by tracker and project membership.
demo_roles = roles.values_at(:requirement_author, :verification_engineer, :process_qa)
all_trackers.each do |tracker|
  demo_roles.each do |role|
    IssueStatus.find_each do |old_status|
      IssueStatus.find_each do |new_status|
        WorkflowTransition.find_or_create_by!(
          tracker_id: tracker.id,
          role_id: role.id,
          old_status_id: old_status.id,
          new_status_id: new_status.id
        )
      end
    end
  end
end

paths = [
  {
    code: "GP-01", name: "RSOC LED indication", token: "LED",
    creq: "電量狀態必須以四段 LED 清楚呈現給使用者。",
    sys: "系統應依 RSOC 0-24/25-49/50-74/75-100% 顯示一至四段 LED。",
    swr: "軟體應將 RSOC 百分比映射為 1 至 4 個啟用 LED 區段。",
    unit: "RSOC LED segment mapping", file: "aspice-demo/src/rsoc_led.c", symbol: "rsoc_led_segments",
    results: { sys4: "Pass", sys5: "Not Executed", swe4: "Pass", swe5: "Pass", swe6: "Pass" }
  },
  {
    code: "GP-02", name: "over-voltage protection", token: "OVP",
    creq: "電池過電壓時不得繼續充電，且恢復必須具備遲滯。",
    sys: "任一電芯達 4.25 V 時停止充電，降至 4.05 V 後才允許恢復。",
    swr: "軟體應以 4.25 V trip 與 4.05 V release 門檻控制充電允許狀態。",
    unit: "OVP hysteresis monitor", file: "aspice-demo/src/ovp_monitor.c", symbol: "ovp_charge_allowed",
    results: { sys4: "Pass", sys5: "Not Executed", swe4: "Pass", swe5: "Fail", swe6: "Blocked" }
  },
  {
    code: "GP-03", name: "charging mode threshold", token: "CHG",
    creq: "產品必須可靠辨識充電狀態。",
    sys: "充電電流達 25 mA 以上時，系統應進入充電模式。",
    swr: "軟體應以 25 mA 門檻判定充電模式並提供狀態給上層功能。",
    unit: "Charging mode threshold evaluator", file: "aspice-demo/src/charging_mode.c", symbol: "charging_mode_active",
    results: { sys4: "Not Executed", sys5: "Not Executed", swe4: "Pass", swe5: "Pass", swe6: "Not Executed" }
  },
  {
    code: "GP-04", name: "UART supervision", token: "UART",
    creq: "控制器通訊異常必須可被偵測並回報。",
    sys: "UART 在監督時間內未收到有效訊框時，系統應宣告通訊逾時。",
    swr: "軟體應比較訊框經過時間與設定 timeout，並輸出 UART link timeout 狀態。",
    unit: "UART timeout monitor", file: "aspice-demo/src/uart_monitor.c", symbol: "uart_link_timed_out",
    results: { sys4: "Blocked", sys5: "Not Executed", swe4: "Fail", swe5: "Blocked", swe6: "Not Executed" }
  },
  {
    code: "GP-05", name: "AFE SOC estimation", token: "SOC",
    creq: "產品應提供 0 至 100% 的電池剩餘電量。",
    sys: "系統應使用 AFE 累積容量與額定容量計算 SOC，結果限制於 0 至 100%。",
    swr: "軟體應計算 accumulated_mAh/capacity_mAh，並將 SOC clamp 至 0..100%。",
    unit: "AFE SOC estimator", file: "aspice-demo/src/soc_estimator.c", symbol: "soc_estimate_percent",
    results: { sys4: "Pass", sys5: "Pass", swe4: "Pass", swe5: "Pass", swe6: "Pass" }
  }
]

def issue_by_trace_id(project, trace_field, trace_id)
  Issue.joins(:custom_values).find_by(
    project_id: project.id,
    custom_values: { custom_field_id: trace_field.id, value: trace_id }
  )
end

def ensure_issue(project:, tracker:, author:, status:, priority:, subject:, description:, parent:, values:, trace_field:, assigned_to: nil)
  trace_id = values.fetch(trace_field.id)
  issue = issue_by_trace_id(project, trace_field, trace_id) || Issue.new(project: project)
  structured_steps = IssueCustomField.find_by(name: "Test Steps")
  preserve_test_form = issue.persisted? && structured_steps && issue.custom_field_value(structured_steps).present?
  if preserve_test_form
    verification_result = IssueCustomField.find_by(name: "Verification Result")
    values = values.except(verification_result.id) if verification_result
  end
  issue.tracker = tracker
  issue.author = author
  issue.status = status
  issue.priority = priority
  issue.subject = subject
  issue.description = description unless preserve_test_form
  issue.parent_issue_id = parent&.id
  issue.assigned_to = assigned_to
  issue.custom_field_values = values.transform_keys(&:to_s)
  issue.save!
  issue
end

def common_values(fields, trace_id:, golden_path:, process:, review: "Approved", baseline: "ASPICE-DEMO-BL1")
  {
    fields[:trace_id].id => trace_id,
    fields[:golden_path].id => golden_path,
    fields[:aspice_process].id => process,
    fields[:review_status].id => review,
    fields[:baseline].id => baseline
  }
end

def ensure_relation(test_issue, work_product)
  relation = IssueRelation.where(relation_type: "relates").where(
    "(issue_from_id = :test AND issue_to_id = :work) OR " \
    "(issue_from_id = :work AND issue_to_id = :test)",
    test: test_issue.id,
    work: work_product.id
  ).first
  return relation if relation

  relation = IssueRelation.new(issue_from: test_issue, issue_to: work_product, relation_type: "relates")
  relation.save!
end

created = []

verification_labels = {
  sys4: "SYS.4 - System Integration and Integration Verification",
  sys5: "SYS.5 - System Verification",
  swe4: "SWE.4 - Software Unit Verification",
  swe5: "SWE.5 - Software Component and Integration Verification",
  swe6: "SWE.6 - Software Verification"
}

verification_groups = {}
verification_labels.each do |level, label|
  process_code = level.to_s.upcase.sub(/([A-Z]+)(\d+)/, '\\1.\\2')
  verification_groups[level] = ensure_issue(
    project: verification_project,
    tracker: trackers[:verification_group],
    author: admin,
    status: default_status,
    priority: default_priority,
    subject: label,
    description: "Department-owned verification layer covering all five golden paths.",
    parent: nil,
    assigned_to: groups.fetch(level),
    values: common_values(
      fields,
      trace_id: "TRG-VER-#{level.to_s.upcase}",
      golden_path: "",
      process: process_code
    ),
    trace_field: fields[:trace_id]
  )
end

paths.each_with_index do |path, index|
  number = format("%03d", index + 1)
  golden_path = "#{path[:code]} #{path[:name]}"

  requirement_group = ensure_issue(
    project: requirements_project, tracker: trackers[:requirement_group], author: admin,
    status: default_status, priority: default_priority,
    subject: "#{path[:code]} - #{path[:name]}",
    description: "Requirement-side traceability container for #{golden_path}.", parent: nil,
    values: common_values(fields, trace_id: "TRG-REQ-#{number}", golden_path: golden_path, process: "CUSTOMER"),
    trace_field: fields[:trace_id]
  )
  creq = ensure_issue(
    project: requirements_project, tracker: trackers[:customer_requirement], author: admin,
    status: default_status, priority: default_priority,
    subject: "CREQ-#{path[:token]}-#{number} - #{path[:creq]}", description: path[:creq], parent: requirement_group,
    values: common_values(fields, trace_id: "CREQ-#{path[:token]}-#{number}", golden_path: golden_path, process: "CUSTOMER"),
    trace_field: fields[:trace_id]
  )
  sys = ensure_issue(
    project: requirements_project, tracker: trackers[:system_requirement], author: admin,
    status: default_status, priority: default_priority,
    subject: "SYS-#{path[:token]}-#{number} - #{path[:sys]}", description: path[:sys], parent: creq,
    values: common_values(fields, trace_id: "SYS-#{path[:token]}-#{number}", golden_path: golden_path, process: "SYS.2"),
    trace_field: fields[:trace_id]
  )
  swr = ensure_issue(
    project: requirements_project, tracker: trackers[:software_requirement], author: admin,
    status: default_status, priority: default_priority,
    subject: "SWR-#{path[:token]}-#{number} - #{path[:swr]}", description: path[:swr], parent: sys,
    values: common_values(fields, trace_id: "SWR-#{path[:token]}-#{number}", golden_path: golden_path, process: "SWE.1"),
    trace_field: fields[:trace_id]
  )
  source_url = "#{SOURCE_REPOSITORY}/blob/#{SOURCE_COMMIT}/#{path[:file]}"
  unit_values = common_values(
    fields, trace_id: "SWU-#{path[:token]}-#{number}", golden_path: golden_path, process: "SWE.3"
  ).merge(
    fields[:git_repository].id => SOURCE_REPOSITORY,
    fields[:git_commit].id => SOURCE_COMMIT,
    fields[:source_file].id => path[:file],
    fields[:source_symbol].id => path[:symbol],
    fields[:source_url].id => source_url
  )
  unit = ensure_issue(
    project: requirements_project, tracker: trackers[:software_unit], author: admin,
    status: default_status, priority: default_priority,
    subject: "SWU-#{path[:token]}-#{number} - #{path[:unit]}",
    description: "Software unit implementing #{path[:swr]}\n\nImmutable source: #{source_url}", parent: swr,
    values: unit_values, trace_field: fields[:trace_id]
  )

  verification_targets = {
    sys4: [sys],
    sys5: [sys],
    swe4: [unit],
    swe5: [swr, unit],
    swe6: [swr]
  }
  verification_targets.each do |level, targets|
    result = path[:results].fetch(level)
    test_trace_id = "TC-#{level.to_s.upcase}-#{path[:token]}-#{number}"
    process_code = level.to_s.upcase.sub(/([A-Z]+)(\d+)/, '\\1.\\2')
    values = common_values(
      fields, trace_id: test_trace_id, golden_path: golden_path, process: process_code
    ).merge(fields[:verification_result].id => result)
    test_issue = ensure_issue(
      project: verification_project, tracker: trackers.fetch(level), author: admin,
      status: result == "Pass" ? resolved_status : default_status,
      priority: default_priority,
      subject: "#{test_trace_id} - #{verification_labels.fetch(level)}: #{path[:name]}",
      description: [
        "Objective: verify #{path[:name]} at #{level.to_s.upcase} level.",
        "Method: execute the defined nominal and boundary conditions against baseline ASPICE-DEMO-BL1.",
        "Expected: behavior remains consistent with the linked work product.",
        "Demo verdict: #{result}."
      ].join("\n\n"),
      parent: verification_groups.fetch(level),
      assigned_to: groups.fetch(level),
      values: values,
      trace_field: fields[:trace_id]
    )
    targets.each { |target| ensure_relation(test_issue, target) }
    created << test_issue
  end

  created.concat([requirement_group, creq, sys, swr, unit])
end

# Migrate the original golden-path-owned verification roots after their test
# cases have been moved under department-owned process roots.
(1..5).each do |index|
  legacy_trace_id = "TRG-VER-#{format('%03d', index)}"
  legacy_group = issue_by_trace_id(verification_project, fields[:trace_id], legacy_trace_id)
  legacy_group&.destroy!
end

result_colors = {
  "Pass" => "#16a34a",
  "Fail" => "#dc2626",
  "Blocked" => "#d97706",
  "Not Executed" => "#64748b"
}
levels = %i[sys4 sys5 swe4 swe5 swe6]
level_labels = {
  sys4: "SYS.4", sys5: "SYS.5", swe4: "SWE.4", swe5: "SWE.5", swe6: "SWE.6"
}
test_issues = paths.each_with_index.to_h do |path, index|
  number = format("%03d", index + 1)
  tests = levels.to_h do |level|
    trace_id = "TC-#{level.to_s.upcase}-#{path[:token]}-#{number}"
    [level, issue_by_trace_id(verification_project, fields[:trace_id], trace_id)]
  end
  [path[:code], tests]
end
result_counts = result_colors.keys.to_h do |result|
  count = test_issues.values.flat_map(&:values).compact.count do |issue|
    issue.custom_field_value(fields[:verification_result]) == result
  end
  [result, count]
end
covered_paths = test_issues.count { |_code, tests| levels.all? { |level| tests[level].present? } }
coverage_percent = (covered_paths * 100.0 / paths.size).round
pass_angle = (result_counts["Pass"] * 360.0 / 25).round(1)
fail_angle = pass_angle + (result_counts["Fail"] * 360.0 / 25).round(1)
blocked_angle = fail_angle + (result_counts["Blocked"] * 360.0 / 25).round(1)

matrix_rows = paths.map do |path|
  cells = levels.map do |level|
    issue = test_issues.fetch(path[:code]).fetch(level)
    result = issue.custom_field_value(fields[:verification_result])
    %(<td><a class="aspice-result aspice-#{result.downcase.tr(' ', '-')}" href="/issues/#{issue.id}">#{result}</a></td>)
  end.join
  %(<tr><th><span>#{path[:code]}</span>#{path[:name]}</th>#{cells}</tr>)
end.join

legend = result_counts.map do |result, count|
  %(<span><i style="background:#{result_colors.fetch(result)}"></i>#{result} <b>#{count}</b></span>)
end.join

dashboard_css = <<~CSS
  #aspice-dashboard { clear:both; color:#172033; max-width:1400px; margin:0 auto; }
  #aspice-dashboard * { box-sizing:border-box; }
  #aspice-dashboard .aspice-head { display:flex; justify-content:space-between; gap:24px; align-items:flex-end; margin:6px 0 24px; padding-bottom:18px; border-bottom:1px solid #d9e0e9; }
  #aspice-dashboard h1 { margin:0 0 6px; font-size:28px; letter-spacing:0; }
  #aspice-dashboard .aspice-sub { margin:0; color:#526078; font-size:14px; }
  #aspice-dashboard .aspice-actions { display:flex; gap:8px; flex-wrap:wrap; }
  #aspice-dashboard .aspice-button { display:inline-flex; align-items:center; gap:7px; padding:9px 13px; border:1px solid #b8c5d6; border-radius:6px; background:#fff; color:#174ea6; font-weight:600; text-decoration:none; }
  #aspice-dashboard .aspice-button.primary { color:#fff; border-color:#1559c7; background:#1559c7; }
  #aspice-dashboard .aspice-grid { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:14px; margin-bottom:26px; }
  #aspice-dashboard .aspice-card { border:1px solid #d9e0e9; border-radius:7px; background:#fff; padding:18px; min-width:0; }
  #aspice-dashboard .aspice-card-title { position:relative; display:flex; align-items:center; justify-content:space-between; gap:12px; margin:0 0 16px; }
  #aspice-dashboard .aspice-card h3 { margin:0; font-size:16px; letter-spacing:0; }
  #aspice-dashboard .aspice-note { position:relative; flex:0 0 auto; }
  #aspice-dashboard .aspice-note summary { display:grid; place-content:center; width:22px; height:22px; border:1px solid #9cacbf; border-radius:50%; color:#526078; background:#fff; font:700 13px/1 Georgia,serif; cursor:pointer; list-style:none; }
  #aspice-dashboard .aspice-note summary::-webkit-details-marker { display:none; }
  #aspice-dashboard .aspice-note summary:hover,#aspice-dashboard .aspice-note[open] summary { color:#fff; border-color:#1559c7; background:#1559c7; }
  #aspice-dashboard .aspice-note-panel { display:none; position:absolute; z-index:10; top:30px; right:0; width:280px; padding:13px 14px; border:1px solid #b8c5d6; border-radius:6px; background:#fff; box-shadow:0 8px 24px rgba(23,32,51,.16); color:#344054; font-size:12px; font-weight:400; line-height:1.5; }
  #aspice-dashboard .aspice-note[open] .aspice-note-panel,#aspice-dashboard .aspice-note:hover .aspice-note-panel { display:block; }
  #aspice-dashboard .aspice-note-panel strong { display:block; margin-bottom:4px; color:#172033; font-size:13px; }
  #aspice-dashboard .aspice-chart { display:flex; align-items:center; justify-content:center; min-height:190px; gap:22px; }
  #aspice-dashboard .aspice-donut { position:relative; width:144px; height:144px; flex:0 0 144px; border-radius:50%; }
  #aspice-dashboard .aspice-donut:after { content:""; position:absolute; inset:27px; border-radius:50%; background:#fff; }
  #aspice-dashboard .aspice-donut strong { position:absolute; z-index:1; inset:0; display:grid; place-content:center; text-align:center; font-size:25px; line-height:1.1; }
  #aspice-dashboard .aspice-donut strong small { display:block; margin-top:5px; color:#667085; font-size:11px; font-weight:500; }
  #aspice-dashboard .aspice-products { background:conic-gradient(#2563eb 0 10%,#0f766e 10% 20%,#c2410c 20% 30%,#7c3aed 30% 40%,#475569 40% 90%,#cbd5e1 90% 100%); }
  #aspice-dashboard .aspice-coverage { background:conic-gradient(#0f9f7f 0 #{coverage_percent}%,#dc2626 #{coverage_percent}% 100%); }
  #aspice-dashboard .aspice-verdicts { background:conic-gradient(#16a34a 0 #{pass_angle}deg,#dc2626 #{pass_angle}deg #{fail_angle}deg,#d97706 #{fail_angle}deg #{blocked_angle}deg,#64748b #{blocked_angle}deg 360deg); }
  #aspice-dashboard .aspice-legend { display:flex; flex-direction:column; gap:9px; font-size:12px; color:#526078; }
  #aspice-dashboard .aspice-legend span { display:flex; align-items:center; gap:7px; }
  #aspice-dashboard .aspice-legend i { width:9px; height:9px; border-radius:2px; }
  #aspice-dashboard .aspice-legend b { margin-left:auto; color:#172033; }
  #aspice-dashboard .aspice-section-head { display:flex; align-items:baseline; justify-content:space-between; gap:20px; margin:0 0 12px; }
  #aspice-dashboard .aspice-section-head h2 { margin:0; font-size:20px; letter-spacing:0; }
  #aspice-dashboard .aspice-section-head span { color:#667085; font-size:12px; }
  #aspice-dashboard .aspice-matrix-wrap { overflow-x:auto; border:1px solid #d9e0e9; border-radius:7px; }
  #aspice-dashboard .aspice-matrix { width:100%; min-width:760px; border-collapse:collapse; background:#fff; }
  #aspice-dashboard .aspice-matrix th,#aspice-dashboard .aspice-matrix td { padding:12px 14px; border-bottom:1px solid #e5e9f0; text-align:center; }
  #aspice-dashboard .aspice-matrix thead th { color:#526078; background:#f6f8fb; font-size:12px; text-transform:uppercase; }
  #aspice-dashboard .aspice-matrix tbody th { width:34%; text-align:left; font-weight:500; }
  #aspice-dashboard .aspice-matrix tbody th span { display:inline-block; min-width:58px; margin-right:8px; color:#1559c7; font-weight:700; }
  #aspice-dashboard .aspice-matrix tr:last-child th,#aspice-dashboard .aspice-matrix tr:last-child td { border-bottom:0; }
  #aspice-dashboard .aspice-result { display:inline-block; min-width:88px; padding:5px 7px; border-radius:4px; color:#fff; font-size:11px; font-weight:700; text-decoration:none; }
  #aspice-dashboard .aspice-pass { background:#16a34a; }
  #aspice-dashboard .aspice-fail { background:#dc2626; }
  #aspice-dashboard .aspice-blocked { background:#d97706; }
  #aspice-dashboard .aspice-not-executed { background:#64748b; }
  @media (max-width:900px) { #aspice-dashboard .aspice-grid { grid-template-columns:1fr; } #aspice-dashboard .aspice-head { align-items:flex-start; flex-direction:column; } }
CSS

dashboard_html = <<~HTML
  <div id="aspice-dashboard">
    <div class="aspice-head">
      <div><h1>ASPICE Traceability Dashboard</h1><p class="aspice-sub">Five Golden Paths from customer intent to verification evidence</p></div>
      <div class="aspice-actions">
        <a class="aspice-button primary" href="/projects/aspice-requirements/issues_trees/tree_index">Requirement Tree</a>
        <a class="aspice-button" href="/projects/aspice-verification/issues_trees/tree_index">Verification Tree</a>
      </div>
    </div>
    <div class="aspice-grid">
      <section class="aspice-card"><div class="aspice-card-title"><h3>Traceability Records</h3><details class="aspice-note"><summary aria-label="Explain Traceability Records">i</summary><div class="aspice-note-panel"><strong>What is being managed?</strong>Shows the number and composition of traceable work products: CReq, SYS, SWR, SWU, and Test Cases. The 45 records exclude grouping containers.</div></details></div><div class="aspice-chart"><div class="aspice-donut aspice-products"><strong>45<small>work products</small></strong></div><div class="aspice-legend"><span><i style="background:#2563eb"></i>CReq<b>5</b></span><span><i style="background:#0f766e"></i>SYS<b>5</b></span><span><i style="background:#c2410c"></i>SWR<b>5</b></span><span><i style="background:#7c3aed"></i>SWU<b>5</b></span><span><i style="background:#475569"></i>Test Case<b>25</b></span></div></div></section>
      <section class="aspice-card"><div class="aspice-card-title"><h3>End-to-End Coverage</h3><details class="aspice-note"><summary aria-label="Explain End-to-End Coverage">i</summary><div class="aspice-note-panel"><strong>Are the trace links complete?</strong>Measures how many Golden Paths connect customer intent through requirements, software units, and verification evidence. Coverage does not mean the tests have passed.</div></details></div><div class="aspice-chart"><div class="aspice-donut aspice-coverage"><strong>#{coverage_percent}%<small>#{covered_paths} of #{paths.size} paths</small></strong></div><div class="aspice-legend"><span><i style="background:#0f9f7f"></i>Covered<b>#{covered_paths}</b></span><span><i style="background:#dc2626"></i>Gap<b>#{paths.size - covered_paths}</b></span></div></div></section>
      <section class="aspice-card"><div class="aspice-card-title"><h3>Verification Results</h3><details class="aspice-note"><summary aria-label="Explain Verification Results">i</summary><div class="aspice-note-panel"><strong>How is verification progressing?</strong>Shows the latest verdict for all 25 test cases across SYS.4, SYS.5, SWE.4, SWE.5, and SWE.6. Pass rate is separate from traceability coverage.</div></details></div><div class="aspice-chart"><div class="aspice-donut aspice-verdicts"><strong>#{result_counts['Pass']} / 25<small>passed test cases</small></strong></div><div class="aspice-legend">#{legend}</div></div></section>
    </div>
    <div class="aspice-section-head"><h2>Golden Path Verification Matrix</h2><span>Click a verdict to open its evidence</span></div>
    <div class="aspice-matrix-wrap"><table class="aspice-matrix"><thead><tr><th>Golden Path</th>#{levels.map { |level| "<th>#{level_labels.fetch(level)}</th>" }.join}</tr></thead><tbody>#{matrix_rows}</tbody></table></div>
  </div>
HTML

wiki = root_project.wiki || Wiki.create!(project: root_project, start_page: "ASPICE_Dashboard", status: 1)
wiki.update!(start_page: "ASPICE_Dashboard")
page = WikiPage.find_or_initialize_by(wiki: wiki, title: "ASPICE_Dashboard")
page.protected = true
page.save!
content = page.content || WikiContent.new(page: page)
dashboard_text = "{{aspice_dashboard}}"
if content.new_record? || content.text != dashboard_text
  content.author = admin
  content.comments = "Refresh ASPICE demo dashboard"
  content.text = dashboard_text
  content.save!
end

puts "PROJECTS=#{[root_project, requirements_project, verification_project].map(&:identifier).join(',')}"
puts "TRACKERS=#{trackers.values.map(&:name).join(',')}"
puts "CUSTOM_FIELDS=#{fields.values.map(&:name).join(',')}"
puts "TREE_VIEW_DEFAULT=#{Setting.plugin_redmine_issues_tree['default_redirect_to_tree_view']}"
puts "SAVED_QUERIES=#{IssueQuery.where(project_id: [requirements_project.id, verification_project.id]).count}"
puts "WIKI_START_PAGE=#{wiki.start_page}"
puts "DMSF_WORKFLOW=#{approval_workflow.name}:#{approval_workflow.dmsf_workflow_steps.count}_steps"
puts "DMSF_FOLDER=#{controlled_folder.title}"
puts "DMSF_DEMO_USERS=#{demo_users.values.map(&:login).join(',')}"
puts "ISSUES=#{Issue.where(project_id: [requirements_project.id, verification_project.id]).count}"
puts "RELATIONS=#{IssueRelation.count}"
puts "SOURCE_COMMIT=#{SOURCE_COMMIT}"
end

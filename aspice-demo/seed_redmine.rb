# frozen_string_literal: true

# Run inside the Redmine container with:
#   bundle exec rails runner /tmp/seed_redmine.rb

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
  verification_engineer: ensure_role("ASPICE Verification Engineer", developer_permissions),
  process_qa: ensure_role("ASPICE Process QA", developer_permissions),
  observer: ensure_role("ASPICE Observer", observer_permissions)
}

def ensure_group(name)
  group = Group.find_or_initialize_by(lastname: name)
  group.save!
  group
end

groups = {
  requirements: ensure_group("ASPICE Requirement Team"),
  verification: ensure_group("ASPICE Verification Team"),
  process_qa: ensure_group("ASPICE Process QA Team")
}

def ensure_membership(project, principal, role)
  member = Member.find_or_initialize_by(project: project, principal: principal)
  member.roles = (member.roles + [role]).uniq
  member.save!
end

ensure_membership(requirements_project, groups[:requirements], roles[:requirement_author])
ensure_membership(verification_project, groups[:requirements], roles[:observer])
ensure_membership(requirements_project, groups[:verification], roles[:observer])
ensure_membership(verification_project, groups[:verification], roles[:verification_engineer])
ensure_membership(requirements_project, groups[:process_qa], roles[:process_qa])
ensure_membership(verification_project, groups[:process_qa], roles[:process_qa])

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
    description: "Demo end-to-end traceability path.", possible_values: path_values, required: true
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

def ensure_issue(project:, tracker:, author:, status:, priority:, subject:, description:, parent:, values:, trace_field:)
  trace_id = values.fetch(trace_field.id)
  issue = issue_by_trace_id(project, trace_field, trace_id) || Issue.new(project: project)
  issue.tracker = tracker
  issue.author = author
  issue.status = status
  issue.priority = priority
  issue.subject = subject
  issue.description = description
  issue.parent_issue_id = parent&.id
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

  verification_group = ensure_issue(
    project: verification_project, tracker: trackers[:verification_group], author: admin,
    status: default_status, priority: default_priority,
    subject: "#{path[:code]} - #{path[:name]}",
    description: "Verification-side traceability container for #{golden_path}.", parent: nil,
    values: common_values(fields, trace_id: "TRG-VER-#{number}", golden_path: golden_path, process: "SYS.4"),
    trace_field: fields[:trace_id]
  )

  verification_targets = {
    sys4: [sys],
    sys5: [sys],
    swe4: [unit],
    swe5: [swr, unit],
    swe6: [swr]
  }
  verification_labels = {
    sys4: "SYS.4 integration verification",
    sys5: "SYS.5 system verification",
    swe4: "SWE.4 unit verification",
    swe5: "SWE.5 component and integration verification",
    swe6: "SWE.6 software verification"
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
      parent: verification_group, values: values, trace_field: fields[:trace_id]
    )
    targets.each { |target| ensure_relation(test_issue, target) }
    created << test_issue
  end

  created.concat([requirement_group, creq, sys, swr, unit, verification_group])
end

puts "PROJECTS=#{[root_project, requirements_project, verification_project].map(&:identifier).join(',')}"
puts "TRACKERS=#{trackers.values.map(&:name).join(',')}"
puts "CUSTOM_FIELDS=#{fields.values.map(&:name).join(',')}"
puts "ISSUES=#{Issue.where(project_id: [requirements_project.id, verification_project.id]).count}"
puts "RELATIONS=#{IssueRelation.count}"
puts "SOURCE_COMMIT=#{SOURCE_COMMIT}"
end

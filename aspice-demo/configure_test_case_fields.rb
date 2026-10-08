# frozen_string_literal: true

# Converts the enriched ASPICE test specifications into fixed, form-like
# Redmine custom fields. Run after enrich_test_cases.rb.

PROJECT_IDENTIFIER = "aspice-verification"
TEST_TRACKERS = [
  "SYS.4 Verification", "SYS.5 Verification", "SWE.4 Verification",
  "SWE.5 Verification", "SWE.6 Verification"
].freeze

FIELDS = [
  ["Test Objective", true, "What is verified and at which integration or verification level."],
  ["Acceptance Criteria", true, "Measurable Pass, Fail, and Blocked decision rules."],
  ["Test Environment and Tools", true, "DUT, bench or HIL, instruments, software tools, and verification method."],
  ["Preconditions", true, "Required baseline, configuration, calibration, links, and initial state."],
  ["Test Data and Boundary Values", true, "Nominal, boundary, robustness, fault, and recovery stimuli."],
  ["Test Steps", true, "Numbered actions that another qualified tester can repeat."],
  ["Expected Results", true, "Expected result corresponding one-to-one with every test step."],
  ["Evidence Required", true, "Raw data, logs, images, coverage, configuration, and review records to retain."],
  ["Actual Result and Observation", false, "Observed behavior and measured values. Do not enter planned values as actual evidence."],
  ["Anomaly or Deviation", false, "Linked anomaly, blocker, deviation, waiver, or none observed."],
  ["Reviewer Conclusion", false, "Independent consistency and completeness conclusion for the evidence package."]
].freeze

def section(text, heading, next_heading = nil)
  start_marker = "h3. #{heading}"
  start_at = text.index(start_marker)
  return "" unless start_at

  body_start = start_at + start_marker.length
  body = text[body_start..]
  if next_heading
    finish = body.index("h3. #{next_heading}")
    body = body[0...finish] if finish
  end
  body.strip
end

def parse_spec(description)
  objective_section = section(description, "Objective and acceptance criteria", "Test environment and preconditions")
  environment_section = section(description, "Test environment and preconditions", "Test steps")
  steps_section = section(description, "Test steps", "Measurement and data-quality rules")
  measurement_section = section(description, "Measurement and data-quality rules", "Traceability and review")

  objective = objective_section.lines.take_while { |line| !line.start_with?("*Pass:") }.join.strip
  acceptance = objective_section.lines.select { |line| line.match?(/^\*(Pass|Fail|Blocked):\*/) }.join.strip
  environment_lines = environment_section.lines.map(&:strip).select { |line| line.start_with?("*") }
  environment = environment_lines.take(3).join("\n")
  preconditions = environment_lines.drop(3).join("\n")

  rows = steps_section.lines.filter_map do |line|
    match = line.strip.match(/^\|(\d+)\|(.+?)\|(.+?)\|(.+?)\|$/)
    [match[1], match[2].strip, match[3].strip, match[4].strip] if match
  end
  steps = rows.map { |number, action, _expected, _evidence| "#{number}. #{action}" }.join("\n")
  expected = rows.map { |number, _action, value, _evidence| "#{number}. #{value}" }.join("\n")
  evidence = rows.map { |number, _action, _expected, value| "#{number}. #{value}" }.join("\n")
  data = rows.select { |number, _action, _expected, _evidence| %w[3 4 5 6].include?(number) }
             .map { |number, action, _expected, _evidence| "#{number}. #{action}" }.join("\n")
  evidence = "#{evidence}\n\n#{measurement_section}".strip

  {
    "Test Objective" => objective,
    "Acceptance Criteria" => acceptance,
    "Test Environment and Tools" => environment,
    "Preconditions" => preconditions,
    "Test Data and Boundary Values" => data,
    "Test Steps" => steps,
    "Expected Results" => expected,
    "Evidence Required" => evidence
  }
end

def execution_values(result, issue)
  case result
  when "Pass"
    {
      "Actual Result and Observation" => "Executed for the stated baseline. Observed values and timing met all acceptance criteria; see attached simulated Demo evidence.",
      "Anomaly or Deviation" => "None observed in the simulated Demo execution.",
      "Reviewer Conclusion" => "Demo evidence package is internally consistent with the requirement link and Pass verdict. Replace simulated assets before a production release."
    }
  when "Fail"
    {
      "Actual Result and Observation" => "Execution completed, but at least one measured response violated the stated acceptance criteria. See the simulated profile attachment.",
      "Anomaly or Deviation" => "DEMO-NC-#{issue.id}: acceptance-criterion deviation is Open; product impact and regression scope require disposition.",
      "Reviewer Conclusion" => "Fail verdict is appropriate. Release is not permitted until the linked nonconformance is resolved or formally dispositioned."
    }
  when "Blocked"
    {
      "Actual Result and Observation" => "No valid result: execution stopped because a prerequisite, environment, interface, or test-data dependency was unavailable.",
      "Anomaly or Deviation" => "DEMO-BLOCKER-#{issue.id}: restore the missing test dependency and execute the complete case; do not convert Blocked to Pass without raw evidence.",
      "Reviewer Conclusion" => "No verification conclusion can be drawn while the case is Blocked."
    }
  else
    {
      "Actual Result and Observation" => "Not executed. No actual measurement is available.",
      "Anomaly or Deviation" => "N/A until execution; planned setup and expected profile are not actual evidence.",
      "Reviewer Conclusion" => "Pending execution and evidence review."
    }
  end
end

project = Project.find_by!(identifier: PROJECT_IDENTIFIER)
trackers = Tracker.where(name: TEST_TRACKERS).to_a
raise "Missing test trackers" unless trackers.size == TEST_TRACKERS.size
author = User.find_by(login: "aspice.author") || User.active.where(admin: true).first
User.current = author

custom_fields = FIELDS.to_h do |name, _required, description|
  field = IssueCustomField.find_or_initialize_by(name: name)
  field.field_format = "text"
  field.description = description
  field.is_required = false
  field.is_for_all = false
  field.is_filter = false
  field.searchable = true
  field.visible = true
  field.editable = true
  field.full_width_layout = "1"
  field.trackers = trackers
  field.projects = (field.projects.to_a + [project]).uniq
  field.save!
  [name, field]
end

result_field = IssueCustomField.find_by!(name: "Verification Result")
issues = Issue.where(project: project, tracker: trackers).includes(:custom_values, :attachments).order(:id)
updated = 0

issues.each do |issue|
  values_assigned = false
  required_names = FIELDS.select { |_name, required, _description| required }.map(&:first)
  if required_names.any? { |name| issue.custom_field_value(custom_fields.fetch(name)).blank? }
    source_description = issue.description.to_s
    unless source_description.include?("TEST-SPEC-V1")
      source_description = issue.journals.order(id: :desc).filter_map do |journal|
        detail = journal.details.find { |item| item.property == "attr" && item.prop_key == "description" }
        detail&.old_value if detail&.old_value.to_s.include?("TEST-SPEC-V1")
      end.first.to_s
    end
    values = parse_spec(source_description)
    raise "Could not parse test steps for issue #{issue.id}" if values["Test Steps"].blank?

    result = issue.custom_field_value(result_field).presence || "Not Executed"
    values.merge!(execution_values(result, issue))
    issue.custom_field_values = values.to_h { |name, value| [custom_fields.fetch(name).id.to_s, value] }
    values_assigned = true
  end

  unless issue.description.start_with?("This Test Case uses the controlled fields")
    issue.init_journal(author, "Move test specification into controlled form fields")
    issue.description = <<~TEXT
      This Test Case uses the controlled fields below for its specification, execution record, and review conclusion.

      The attached setup and profile images are clearly labelled simulated Demo assets. Replace them with configuration-controlled raw laboratory evidence before a production release.
    TEXT
    issue.save!
    updated += 1
  else
    issue.save! if values_assigned
  end
end

FIELDS.each do |name, required, _description|
  field = custom_fields.fetch(name)
  field.update!(is_required: required)
end

required_fields = custom_fields.values.select(&:is_required)
reloaded_issues = Issue.where(id: issues.map(&:id)).to_a
incomplete = reloaded_issues.count do |issue|
  required_fields.any? { |field| issue.custom_field_value(field).blank? }
end

puts "TEST_CASES=#{issues.count}"
puts "FIELDS=#{custom_fields.size}"
puts "REQUIRED_FIELDS=#{required_fields.size}"
puts "UPDATED=#{updated}"
puts "INCOMPLETE=#{incomplete}"
puts "ATTACHMENTS=#{issues.sum { |issue| issue.attachments.count }}"

# frozen_string_literal: true

# Adds execution-ready specifications and clearly labelled demo evidence to the
# 25 ASPICE verification issues. Existing verdicts are preserved.
require "cgi"
require "fileutils"
require "tmpdir"

PROJECT_IDENTIFIER = "aspice-verification"
SPEC_MARKER = "TEST-SPEC-V1"

FUNCTIONS = {
  "LED" => {
    name: "RSOC LED indication",
    stimulus: "RSOC = 0, 24, 25, 49, 50, 74, 75, 99, and 100%",
    expected: "1/2/3/4 LED segments at the specified RSOC boundaries; output stable within 100 ms",
    boundary: "24->25%, 49->50%, and 74->75% transitions",
    recovery: "Cycle RSOC across each boundary in both directions and confirm deterministic output",
    units: "% RSOC", threshold: "25 / 50 / 75% boundaries"
  },
  "OVP" => {
    name: "over-voltage protection",
    stimulus: "Cell voltage ramp from 4.20 V to 4.26 V, then down to 4.04 V",
    expected: "Charging disabled at >=4.25 V and released at <=4.05 V within the allocated reaction time",
    boundary: "4.24, 4.25, and 4.26 V trip points; 4.06, 4.05, and 4.04 V release points",
    recovery: "Hold 4.05 V for 500 ms and confirm charging permission returns without chatter",
    units: "cell voltage (V)", threshold: "Trip 4.25 V / release 4.05 V"
  },
  "CHG" => {
    name: "charging mode threshold",
    stimulus: "Charge-current command = 0, 24, 25, 26, and 100 mA",
    expected: "Charging mode asserted at >=25 mA and deasserted below 25 mA within one task cycle",
    boundary: "24, 25, and 26 mA with ADC tolerance applied",
    recovery: "Repeat ten threshold crossings and confirm no missed or metastable state",
    units: "charge current (mA)", threshold: "25 mA"
  },
  "UART" => {
    name: "UART supervision",
    stimulus: "Valid frames every 100 ms, followed by a 600 ms communication gap and recovery frame",
    expected: "Link timeout asserted after 500 ms +/- one scheduler tick and cleared after a valid frame",
    boundary: "499, 500, and 501 ms frame-age checks",
    recovery: "Restore a valid CRC frame and confirm link state and dependent outputs recover",
    units: "frame age (ms)", threshold: "500 ms timeout"
  },
  "SOC" => {
    name: "AFE SOC estimation",
    stimulus: "accumulated_mAh = -5,000; 0; 25,000; 50,000; 100,000; and 105,000 for 100 Ah capacity",
    expected: "SOC = accumulated_mAh/capacity_mAh x 100 and clamped to the 0..100% range",
    boundary: "Negative accumulation, zero capacity guard, full capacity, and over-capacity inputs",
    recovery: "Return to 50,000 mAh and confirm 50% without retained saturation",
    units: "accumulated capacity", threshold: "Clamp 0..100%"
  }
}.freeze

LEVELS = {
  "SYS.4" => {
    target: "Integrated BMS system elements and physical/logical interfaces",
    environment: "BMS bench, programmable cell simulator, CANoe/CAN logger, oscilloscope, controlled 48 V supply",
    method: "Integrate in the approved sequence and verify interfaces, timing, data exchange, and fault propagation",
    coverage: "System architecture elements, interfaces, integration steps, and regression selection"
  },
  "SYS.5" => {
    target: "Complete BMS system against the system requirement",
    environment: "HIL rack with cell/AFE simulation, calibrated current and voltage channels, CAN measurement",
    method: "Black-box requirement verification using nominal, boundary, fault, and recovery scenarios",
    coverage: "System requirements, operating modes, boundary values, and requirement-to-result traceability"
  },
  "SWE.4" => {
    target: "Software unit implementing the monitored function",
    environment: "Host unit-test runner, production compiler settings, mocks/stubs, static-analysis and coverage tools",
    method: "Call the unit directly with equivalence classes and boundary values; inspect return value and internal state",
    coverage: "Statement and branch coverage; MC/DC where required by the project verification strategy"
  },
  "SWE.5" => {
    target: "Integrated software components and their interfaces",
    environment: "Target ECU or SIL environment, production scheduler, AFE/CAN drivers, trace and timing instrumentation",
    method: "Verify component interaction, interface data, call sequence, timing, resource use, and error propagation",
    coverage: "Software architecture interfaces, integration sequence, component interaction, and regression scope"
  },
  "SWE.6" => {
    target: "Released software baseline against the software requirement",
    environment: "Target ECU/SIL with production binary, calibrated I/O simulation, debugger disabled for black-box runs",
    method: "Execute requirement-based nominal, boundary, robustness, and recovery tests on the released binary",
    coverage: "Software requirements, variants, operating modes, boundary values, and verification-result traceability"
  }
}.freeze

def issue_key(issue)
  match = issue.subject.match(/TC-(SYS4|SYS5|SWE4|SWE5|SWE6)-(LED|OVP|CHG|UART|SOC)-/)
  raise "Unsupported test case #{issue.id}: #{issue.subject}" unless match

  level = match[1].sub(/\A(SYS|SWE)(\d)\z/, '\\1.\\2')
  [level, match[2]]
end

def result_for(issue, field)
  issue.custom_field_value(field).presence || "Not Executed"
end

def description_for(issue, level_code, function_code, result)
  level = LEVELS.fetch(level_code)
  function = FUNCTIONS.fetch(function_code)
  execution = case result
              when "Pass"
                "Executed for the stated baseline. All acceptance criteria met; see the attached simulated demo evidence."
              when "Fail"
                "Executed for the stated baseline. At least one acceptance criterion was not met; a demo nonconformance remains open."
              when "Blocked"
                "Execution blocked by test-environment or dependency readiness. No pass/fail conclusion is permitted."
              else
                "Not executed. Attached figures show the planned setup and expected profile only; they are not execution evidence."
              end
  trace_id = issue.custom_field_value(IssueCustomField.find_by(name: "Trace ID"))
  baseline = issue.custom_field_value(IssueCustomField.find_by(name: "Baseline"))

  <<~TEXT
    <!-- #{SPEC_MARKER} -->
    h2. Test Case Specification

    |_. Field|_. Value|
    |Test Case ID|#{trace_id}|
    |ASPICE process|#{level_code}|
    |Test target|#{level[:target]}|
    |Baseline|#{baseline}|
    |Current verdict|#{result}|
    |Evidence status|#{execution}|

    h3. Objective and acceptance criteria

    Verify *#{function[:name]}* at #{level_code} level. #{function[:expected]}.

    *Pass:* every mandatory step completes, all observed values remain within the stated thresholds/tolerances, the correct baseline is used, and no unresolved severity-1/2 anomaly affects the result.
    *Fail:* execution completes but one or more acceptance criteria are violated.
    *Blocked:* execution cannot complete because a prerequisite, environment, interface, or test-data dependency is unavailable.

    h3. Test environment and preconditions

    * Equipment/environment: #{level[:environment]}
    * Verification method: #{level[:method]}
    * Coverage objective: #{level[:coverage]}
    * DUT flashed with #{baseline}; configuration and calibration checksum recorded.
    * Test instruments are within calibration period; time synchronization error <= 1 ms.
    * Related requirement and architecture links are reviewed before execution.
    * Power-on self-test passes and no unrelated diagnostic trouble code is active.

    h3. Test steps

    |_. Step|_. Action / stimulus|_. Expected result|_. Evidence to retain|
    |1|Record DUT serial number, software checksum, calibration ID, tool versions, and test operator.|Configuration matches #{baseline}; all mandatory fields are captured.|Configuration screenshot and execution log header.|
    |2|Connect and initialize the stated environment; verify signal scaling and communication health.|All channels are valid, timestamped, and within idle-state tolerance.|Setup image, calibration status, and bus trace.|
    |3|Apply nominal stimulus: #{function[:stimulus]}.|Nominal behavior matches the linked requirement with no unexpected diagnostic event.|Input/output trace and measured response time.|
    |4|Exercise boundaries: #{function[:boundary]}.|Transition occurs only at the specified boundary, including measurement tolerance.|Zoomed boundary plot and raw samples.|
    |5|Repeat the critical transition at least three times and include the applicable fault/robustness condition.|Results are deterministic; timing and state remain within acceptance criteria.|Repeated-run log, min/max timing, and anomaly reference if any.|
    |6|Perform recovery: #{function[:recovery]}.|DUT returns to the expected state without reset, latch, chatter, or stale output unless explicitly required.|Recovery trace and final diagnostic status.|
    |7|Export raw data, calculate verdict, link anomalies, and have the reviewer confirm requirement coverage.|Result, evidence, issue links, and reviewer conclusion are complete and mutually consistent.|Signed review record and immutable evidence package.|

    h3. Measurement and data-quality rules

    * Primary axis: #{function[:units]}; decision threshold: #{function[:threshold]}.
    * Record raw stimulus, observed output, timestamps, units, channel names, tool version, and test configuration.
    * Report min/max/mean response time where timing is relevant; do not report only a screenshot.
    * A rerun after test-script or product change requires a new evidence revision and regression rationale.
    * Synthetic images attached to this Demo are labelled *SIMULATED DEMO EVIDENCE* and must not be used as production release evidence.

    h3. Traceability and review

    * Keep bidirectional links to the verified requirement/design item and any anomaly.
    * Reviewer confirms that steps, expected results, actual data, verdict, and linked requirement are consistent.
    * The final release decision is based on raw evidence and anomaly disposition, not the status field alone.
  TEXT
end

def setup_svg(issue, level_code, function_code, result)
  level = LEVELS.fetch(level_code)
  function = FUNCTIONS.fetch(function_code)
  color = { "Pass" => "#16803b", "Fail" => "#c62828", "Blocked" => "#d97706" }.fetch(result, "#64748b")
  title = CGI.escapeHTML(issue.subject)
  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="1200" height="650">
      <rect width="1200" height="650" fill="#f5f7fa"/><rect x="28" y="26" width="1144" height="598" rx="8" fill="white" stroke="#b8c5d6"/>
      <text x="60" y="75" font-family="Arial" font-size="24" font-weight="bold" fill="#172033">Test Setup - #{CGI.escapeHTML(level_code)} / #{CGI.escapeHTML(function[:name])}</text>
      <text x="60" y="108" font-family="Arial" font-size="14" fill="#526078">#{title}</text>
      <rect x="65" y="190" width="250" height="145" rx="6" fill="#e8f0fe" stroke="#2563eb" stroke-width="2"/><text x="190" y="235" text-anchor="middle" font-family="Arial" font-size="19" font-weight="bold" fill="#174ea6">Stimulus / HIL</text><text x="190" y="275" text-anchor="middle" font-family="Arial" font-size="14" fill="#344054">Voltage, current, RSOC</text><text x="190" y="299" text-anchor="middle" font-family="Arial" font-size="14" fill="#344054">UART / AFE simulation</text>
      <rect x="470" y="170" width="260" height="185" rx="6" fill="#eaf7f2" stroke="#0f766e" stroke-width="2"/><text x="600" y="220" text-anchor="middle" font-family="Arial" font-size="20" font-weight="bold" fill="#0f5f59">Device Under Test</text><text x="600" y="258" text-anchor="middle" font-family="Arial" font-size="14" fill="#344054">#{CGI.escapeHTML(level[:target])}</text><text x="600" y="305" text-anchor="middle" font-family="Arial" font-size="13" fill="#526078">Baseline: ASPICE-DEMO-BL1</text>
      <rect x="885" y="190" width="250" height="145" rx="6" fill="#fff6e8" stroke="#d97706" stroke-width="2"/><text x="1010" y="235" text-anchor="middle" font-family="Arial" font-size="19" font-weight="bold" fill="#9a5700">Measurement</text><text x="1010" y="275" text-anchor="middle" font-family="Arial" font-size="14" fill="#344054">CAN / trace / scope</text><text x="1010" y="299" text-anchor="middle" font-family="Arial" font-size="14" fill="#344054">Raw data + timestamps</text>
      <line x1="315" y1="262" x2="470" y2="262" stroke="#40516a" stroke-width="3"/><polygon points="470,262 451,252 451,272" fill="#40516a"/><line x1="730" y1="262" x2="885" y2="262" stroke="#40516a" stroke-width="3"/><polygon points="885,262 866,252 866,272" fill="#40516a"/>
      <rect x="65" y="430" width="1070" height="115" rx="5" fill="#f8fafc" stroke="#d5dce5"/><text x="90" y="468" font-family="Arial" font-size="16" font-weight="bold" fill="#172033">Acceptance criterion</text><text x="90" y="500" font-family="Arial" font-size="14" fill="#344054">#{CGI.escapeHTML(function[:expected])}</text>
      <rect x="895" y="48" width="240" height="42" rx="5" fill="#{color}"/><text x="1015" y="75" text-anchor="middle" font-family="Arial" font-size="15" font-weight="bold" fill="white">#{CGI.escapeHTML(result.upcase)}</text>
      <text x="600" y="598" text-anchor="middle" font-family="Arial" font-size="13" font-weight="bold" fill="#b42318">SIMULATED DEMO ASSET - NOT PRODUCTION EVIDENCE</text>
    </svg>
  SVG
end

def evidence_svg(issue, level_code, function_code, result)
  function = FUNCTIONS.fetch(function_code)
  color = { "Pass" => "#16803b", "Fail" => "#c62828", "Blocked" => "#d97706" }.fetch(result, "#64748b")
  trace = result == "Fail" ? "120,470 250,445 380,420 510,365 640,280 770,235 900,205 1050,190" : "120,475 250,455 380,420 510,365 640,310 770,255 900,210 1050,180"
  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="1200" height="650">
      <rect width="1200" height="650" fill="#f5f7fa"/><rect x="28" y="26" width="1144" height="598" rx="8" fill="white" stroke="#b8c5d6"/>
      <text x="60" y="74" font-family="Arial" font-size="24" font-weight="bold" fill="#172033">Verification Profile - #{CGI.escapeHTML(function[:name])}</text>
      <text x="60" y="106" font-family="Arial" font-size="14" fill="#526078">#{CGI.escapeHTML(issue.subject)} | #{CGI.escapeHTML(level_code)}</text>
      <line x1="105" y1="520" x2="1090" y2="520" stroke="#526078" stroke-width="2"/><line x1="105" y1="155" x2="105" y2="520" stroke="#526078" stroke-width="2"/>
      <g stroke="#e1e6ed" stroke-width="1"><line x1="105" y1="430" x2="1090" y2="430"/><line x1="105" y1="340" x2="1090" y2="340"/><line x1="105" y1="250" x2="1090" y2="250"/><line x1="105" y1="160" x2="1090" y2="160"/></g>
      <line x1="105" y1="315" x2="1090" y2="315" stroke="#d97706" stroke-width="2" stroke-dasharray="9 7"/><text x="1080" y="302" text-anchor="end" font-family="Arial" font-size="13" fill="#9a5700">#{CGI.escapeHTML(function[:threshold])}</text>
      <polyline points="#{trace}" fill="none" stroke="#2563eb" stroke-width="5"/><g fill="#2563eb"><circle cx="120" cy="#{result == 'Fail' ? 470 : 475}" r="6"/><circle cx="510" cy="365" r="6"/><circle cx="770" cy="#{result == 'Fail' ? 235 : 255}" r="6"/><circle cx="1050" cy="#{result == 'Fail' ? 190 : 180}" r="6"/></g>
      <text x="600" y="562" text-anchor="middle" font-family="Arial" font-size="14" fill="#526078">Stimulus sequence / time</text><text x="58" y="340" transform="rotate(-90 58 340)" text-anchor="middle" font-family="Arial" font-size="14" fill="#526078">#{CGI.escapeHTML(function[:units])}</text>
      <rect x="850" y="50" width="275" height="42" rx="5" fill="#{color}"/><text x="987" y="77" text-anchor="middle" font-family="Arial" font-size="15" font-weight="bold" fill="white">#{CGI.escapeHTML(result.upcase)}</text>
      <text x="600" y="600" text-anchor="middle" font-family="Arial" font-size="13" font-weight="bold" fill="#b42318">SIMULATED DEMO EVIDENCE - REPLACE WITH RAW LAB DATA</text>
    </svg>
  SVG
end

def render_png(path, issue, level_code, function_code, result, kind)
  function = FUNCTIONS.fetch(function_code)
  color = { "Pass" => "#16803b", "Fail" => "#c62828", "Blocked" => "#d97706" }.fetch(result, "#64748b")
  title = kind == :setup ? "TEST SETUP" : "VERIFICATION PROFILE"
  command = [
    "magick", "-size", "1200x650", "xc:#f5f7fa",
    "-fill", "white", "-stroke", "#b8c5d6", "-strokewidth", "2", "-draw", "roundrectangle 28,26 1172,624 8,8",
    "-fill", "#172033", "-stroke", "none", "-pointsize", "25", "-annotate", "+60+74", "#{title} - #{level_code}",
    "-fill", "#526078", "-pointsize", "16", "-annotate", "+60+108", function[:name],
    "-fill", color, "-draw", "roundrectangle 880,48 1135,92 5,5", "-fill", "white", "-pointsize", "16", "-gravity", "northwest", "-annotate", "+955+61", result.upcase,
    "-gravity", "northwest"
  ]

  if kind == :setup
    command.concat([
      "-fill", "#e8f0fe", "-stroke", "#2563eb", "-draw", "roundrectangle 65,190 315,335 6,6",
      "-fill", "#eaf7f2", "-stroke", "#0f766e", "-draw", "roundrectangle 470,170 730,355 6,6",
      "-fill", "#fff6e8", "-stroke", "#d97706", "-draw", "roundrectangle 885,190 1135,335 6,6",
      "-fill", "#174ea6", "-stroke", "none", "-pointsize", "20", "-annotate", "+118+238", "Stimulus / HIL",
      "-fill", "#0f5f59", "-annotate", "+505+220", "Device Under Test",
      "-fill", "#9a5700", "-annotate", "+940+238", "Measurement",
      "-fill", "#344054", "-pointsize", "14", "-annotate", "+105+280", "Calibrated input",
      "-annotate", "+520+275", "#{level_code} target baseline",
      "-annotate", "+940+280", "Raw data + timing",
      "-stroke", "#40516a", "-strokewidth", "4", "-draw", "line 315,262 470,262 line 730,262 885,262",
      "-fill", "#f8fafc", "-stroke", "#d5dce5", "-strokewidth", "1", "-draw", "roundrectangle 65,430 1135,545 5,5",
      "-fill", "#172033", "-stroke", "none", "-pointsize", "17", "-annotate", "+90+468", "Acceptance criterion",
      "-fill", "#344054", "-pointsize", "14", "-annotate", "+90+505", "Threshold: #{function[:threshold]} | retain configuration, raw log, and review record"
    ])
  else
    trace = result == "Fail" ? "polyline 120,470 250,445 380,420 510,365 640,280 770,235 900,205 1050,190" : "polyline 120,475 250,455 380,420 510,365 640,310 770,255 900,210 1050,180"
    command.concat([
      "-stroke", "#526078", "-strokewidth", "2", "-draw", "line 105,520 1090,520 line 105,155 105,520",
      "-stroke", "#e1e6ed", "-strokewidth", "1", "-draw", "line 105,430 1090,430 line 105,340 1090,340 line 105,250 1090,250 line 105,160 1090,160",
      "-stroke", "#d97706", "-strokewidth", "2", "-draw", "line 105,315 1090,315",
      "-fill", "#9a5700", "-stroke", "none", "-pointsize", "14", "-annotate", "+820+300", "Decision threshold: #{function[:threshold]}",
      "-fill", "none", "-stroke", "#2563eb", "-strokewidth", "5", "-draw", trace,
      "-fill", "#526078", "-stroke", "none", "-pointsize", "14", "-annotate", "+485+560", "Stimulus sequence / time",
      "-annotate", "+120+145", "Measured response profile"
    ])
  end

  command.concat([
    "-fill", "#b42318", "-stroke", "none", "-pointsize", "14", "-annotate", "+365+600", "SIMULATED DEMO ASSET - REPLACE WITH RAW LAB EVIDENCE",
    path
  ])
  system(*command) || raise("Image generation failed for #{path}")
end

def attach_png(issue, author, filename, description, level_code, function_code, result, kind)
  return false if issue.attachments.exists?(filename: filename)

  Dir.mktmpdir("aspice-evidence") do |dir|
    png_path = File.join(dir, filename)
    render_png(png_path, issue, level_code, function_code, result, kind)
    upload = ActionDispatch::Http::UploadedFile.new(
      filename: filename, type: "image/png", tempfile: File.open(png_path, "rb")
    )
    Attachment.create!(container: issue, file: upload, author: author, description: description)
  end
  true
end

project = Project.find_by!(identifier: PROJECT_IDENTIFIER)
result_field = IssueCustomField.find_by!(name: "Verification Result")
author = User.find_by(login: "aspice.author") || User.active.where(admin: true).first
User.current = author
issues = Issue.where(project: project).joins(:tracker).where.not(trackers: { name: "Verification Trace Group" }).order(:id)
updated = 0
attachments = 0

issues.each do |issue|
  level_code, function_code = issue_key(issue)
  result = result_for(issue, result_field)
  unless issue.description.to_s.include?(SPEC_MARKER)
    issue.init_journal(author, "Expand Demo test steps, acceptance criteria, and evidence guidance")
    issue.description = description_for(issue, level_code, function_code, result)
    issue.save!
    updated += 1
  end

  base = issue.subject[/TC-[A-Z0-9-]+/].downcase
  attachments += 1 if attach_png(issue, author, "#{base}_setup.png", "Simulated Demo test setup; replace with an approved lab configuration image.", level_code, function_code, result, :setup)
  attachments += 1 if attach_png(issue, author, "#{base}_evidence.png", "Simulated Demo verification profile; replace with raw execution evidence for release.", level_code, function_code, result, :evidence)
end

puts "TEST_CASES=#{issues.count}"
puts "UPDATED=#{updated}"
puts "ATTACHMENTS_CREATED=#{attachments}"
puts "TOTAL_ATTACHMENTS=#{issues.sum { |issue| issue.attachments.count }}"

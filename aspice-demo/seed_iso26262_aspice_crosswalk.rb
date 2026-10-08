# frozen_string_literal: true

# Creates a root-level DMSF crosswalk between the ISO 26262 and Automotive
# SPICE work-product frameworks in enterprise-demo.
require "digest"
require "fileutils"

PROJECT_IDENTIFIER = "aspice-requirements"
FILENAME = "ISO26262_Automotive_SPICE_Work_Product_Crosswalk.md"
TITLE = "ISO 26262 and Automotive SPICE Work Product Crosswalk"

CROSSWALK = [
  ["Governance", "Document and evidence register", "DOC-001", "ASP-002", "Shared", "Use ASP-002 as the master project evidence index; add ISO safety classification, confirmation status, and Safety Case references required by DOC-001."],
  ["Governance", "Lifecycle scope and tailoring", "DOC-002", "ASP-001", "Shared with extensions", "Maintain one tailoring matrix. Record both ISO 26262 clause applicability and ASPICE process scope/capability targets."],
  ["Governance", "Bidirectional traceability", "DOC-003", "ASP-003", "Shared", "Use one traceability model and one set of Redmine relations. Include hazards, safety goals, FSC, TSR, HSR/SSR, design, tests, and results."],
  ["Governance", "Assessment and audit readiness", "DOC-203, DOC-903", "ASP-004, SUP1-001", "Common evidence", "Reuse reviews, findings, action closure, interview evidence, and independence records; retain separate ISO confirmation conclusions and ASPICE ratings."],
  ["Management", "Project and safety planning", "DOC-201", "MAN3-001", "Shared with extensions", "Use the project plan as the common schedule and resource baseline. The Safety Plan adds safety lifecycle, ASIL, independence, confirmation measures, and safety release gates."],
  ["Management", "Organization and competence", "DOC-202", "MAN3-001, PA3-001, PA3-002", "Shared", "Use one RACI and competence repository; identify functional-safety roles, independence, authorization, and training explicitly."],
  ["Management", "Schedule, monitoring, risks, decisions", "DOC-201", "MAN3-002 to MAN3-005", "Common evidence", "Reference common project estimates, status, risk, decision, and action records from the Safety Plan rather than copying them."],
  ["Concept", "Item scope and stakeholder context", "DOC-301", "SYS1-001", "Shared with extensions", "Use stakeholder and operational information once. Item Definition adds the safety item boundary, assumptions, dependencies, and vehicle context."],
  ["Concept", "HARA and safety goals", "DOC-302, DOC-303", "SYS1-001, SYS2-001", "ISO-specific analysis", "HARA and ASIL classification remain ISO-controlled. Approved safety goals become stakeholder/system requirement inputs and receive shared trace IDs."],
  ["Concept", "Functional Safety Concept", "DOC-304", "SYS2-001, SYS3-001", "Safety extension", "Manage functional safety requirements in the same requirement repository; FSC adds safe states, FTTI, degraded modes, and safety allocation rationale."],
  ["System", "Technical safety requirements", "DOC-401", "SYS2-001", "Shared with extensions", "Use SYS2 requirements as the source of truth. Tag safety-related requirements with ASIL, safety mechanism, FTTI, and upstream safety-goal links."],
  ["System", "Technical safety concept", "DOC-402", "SYS3-001", "Safety extension", "Use the common system architecture. TSC adds safety-mechanism allocation, independence, freedom from interference, and safety rationale."],
  ["System", "System architecture and interfaces", "DOC-403", "SYS3-001", "Shared", "Maintain one architecture and interface baseline; ISO views reference the same controlled architecture revision."],
  ["System", "System safety analyses", "DOC-404", "SYS2-001, SYS3-001", "ISO-specific analysis", "FMEA/FTA evidence is not replaced by ASPICE architecture analysis. Feed findings and derived requirements back into SYS2/SYS3 with trace links."],
  ["System", "System integration verification", "DOC-405", "SYS4-001, SYS4-002", "Shared", "Use common integration plans, test cases, configurations, results, anomalies, and coverage. Add safety fault injection and timing evidence where applicable."],
  ["System", "Safety validation and system verification", "DOC-406", "SYS5-001, SYS5-002", "Common evidence with different conclusion", "Reuse test environments and results where objectives overlap. SYS5 verifies system requirements; ISO validation concludes achievement of safety goals in representative use."],
  ["Hardware", "Hardware safety requirements", "DOC-501", "HWE1-001", "Shared with extensions", "Use HWE1 as the hardware requirement source; add ASIL, safety classification, diagnostic assumptions, and links to TSRs."],
  ["Hardware", "Hardware architecture and detailed design", "DOC-502", "HWE2-001", "Shared", "Maintain one hardware design and production-data baseline, with ISO safety mechanism and special-characteristic annotations."],
  ["Hardware", "FMEDA and hardware metrics", "DOC-503", "HWE2-001, HWE3-001, HWE4-001", "ISO-specific analysis", "FMEDA, SPFM, LFM, and PMHF remain ISO evidence. Link assumptions to design and use results to select hardware verification measures."],
  ["Hardware", "Dependent failure analysis", "DOC-504", "HWE2-001", "ISO-specific analysis", "Keep DFA as controlled safety analysis; trace mitigations and independence claims to hardware design elements and verification evidence."],
  ["Hardware", "Hardware verification", "DOC-505", "HWE3-001, HWE4-001", "Shared", "Use common verification measures and results. Distinguish verification against hardware design from verification against hardware requirements."],
  ["Software", "Software safety requirements", "DOC-601", "SWE1-001", "Shared with extensions", "Use SWE1 as the requirement source; add ASIL, safety classification, timing, data-integrity, and TSR trace attributes."],
  ["Software", "Software architecture and unit design", "DOC-602", "SWE2-001, SWE3-001", "Shared", "Maintain one software architecture, detailed design, interface, and source baseline. Add FFI and safety-mechanism rationale to the same artifacts."],
  ["Software", "Software safety analysis", "DOC-603", "SWE2-001, SWE3-001", "ISO-specific analysis", "Software FMEA and dependent-failure analysis remain safety evidence; derived actions update architecture, unit design, and requirements."],
  ["Software", "Software verification and coverage", "DOC-604", "SWE4-001/002, SWE5-001/002, SWE6-001/002", "Shared", "Reuse plans, test cases, static-analysis output, results, anomalies, and coverage across both frameworks. Preserve level-specific conclusions."],
  ["Production and field", "Production and end-of-line controls", "DOC-701", "HWE2-001, HWE4-001", "ISO-led with shared data", "Reuse approved production data and compliant-sample evidence; production safety controls remain an ISO Part 7 deliverable."],
  ["Production and field", "Operation, service, emergency, decommissioning", "DOC-702", "SYS1-001", "ISO-specific lifecycle evidence", "Feed operational constraints into stakeholder requirements, but retain the controlled Part 7 manual as the released source."],
  ["Production and field", "Field monitoring and anomaly response", "DOC-703", "SUP9-001", "Shared process", "Use the same problem workflow and evidence; add safety-event criteria, escalation, regulatory actions, and post-release effectiveness review."],
  ["Support", "Configuration and baseline management", "DOC-801", "SUP8-001", "Shared", "Use one configuration-management process, repository, baseline scheme, status accounting, audit, release, and recovery evidence."],
  ["Support", "Document review and control", "DOC-802", "SUP1-001, SUP8-001, SUP-002, PA2-002", "Shared", "Use DMSF revisions and approval history as common evidence. Apply safety independence and signature rules only where required."],
  ["Support", "Tool confidence and qualification", "DOC-803", "PA3-001, PA3-002", "ISO-specific qualification", "ASPICE infrastructure evidence can identify deployed tools, but ISO tool-impact evaluation and qualification conclusions remain separate."],
  ["Support", "Supplier interface and monitoring", "DOC-804", "ACQ4-001, ACQ4-002", "Shared with extensions", "Use one supplier agreement and monitoring record; add allocated safety requirements, safety assumptions, ASIL responsibilities, and confirmation access."],
  ["Support", "Problem resolution", "DOC-805", "SUP9-001", "Shared", "Use one problem register. Safety-impact assessment, affected safety artifacts, and Safety Case impact are mandatory fields for safety-related problems."],
  ["Support", "Change and impact management", "DOC-801", "SUP10-001", "Shared", "Use one change request and impact analysis. Include ISO safety impact, ASIL implications, regression scope, and Safety Case updates."],
  ["Safety case", "Cross-level dependent failure analysis", "DOC-901", "SYS3-001, SWE2-001, HWE2-001", "ISO-specific analysis", "Keep the consolidated analysis separate while linking every dependency, mitigation, architecture decision, and verification result."],
  ["Safety case", "Safety Case", "DOC-902", "ASP-002, ASP-003, ASP-004", "ISO conclusion using shared evidence", "The Safety Case references approved ASPICE work products and evidence but remains the controlled top-level functional-safety argument."],
  ["Capability", "Managed work products and process deployment", "DOC-001, DOC-802", "PA2-001, PA2-002, PA3-001, PA3-002", "ASPICE-specific capability evidence", "Reuse DMSF controls, roles, reviews, and metrics; retain explicit CL2/CL3 evidence and organizational process definitions for assessment."]
].freeze

def crosswalk_content
  rows = CROSSWALK.map do |area, topic, iso, aspice, relation, rule|
    "| #{area} | #{topic} | #{iso} | #{aspice} | #{relation} | #{rule} |"
  end.join("\n")

  <<~MARKDOWN
    # ISO 26262 and Automotive SPICE Work Product Crosswalk

    | Field | Value |
    | --- | --- |
    | Status | Draft |
    | Version | 0.1 |
    | Scope | 48V auxiliary battery/BMS project |
    | ISO baseline | ISO 26262:2018 |
    | Process baseline | Automotive SPICE 4.0 |
    | Owner | Functional Safety Manager / Process Quality Lead |

    ## Purpose

    This table identifies which work products can use one controlled source,
    which evidence can be reused with different conclusions, and which ISO
    26262 safety analyses must remain explicit. It prevents duplicate documents
    while preserving the intent and auditability of both frameworks.

    ## Relationship rules

    - **Shared**: Maintain one controlled artifact and reference the same DMSF revision from both frameworks.
    - **Shared with extensions**: Maintain one source and add ISO/ASPICE-specific attributes or sections.
    - **Common evidence**: Reuse records or test output, but issue separate conclusions when objectives differ.
    - **ISO-specific analysis**: Do not replace this with a generic ASPICE work product; link its inputs, findings, and actions.
    - Redmine issue IDs and relations are the authoritative trace links. Documents summarize and baseline those links.
    - Never copy an approved artifact into both folder trees. Store the source once and use a DMSF link or document reference.

    ## Work-product relationship table

    | Area | Topic | ISO 26262 document | ASPICE work product | Relationship | Recommended implementation |
    | --- | --- | --- | --- | --- | --- |
    #{rows}

    ## Recommended ownership model

    | Artifact class | Primary owner | Required collaborators |
    | --- | --- | --- |
    | Shared requirements and architecture | Engineering process owner | Functional Safety Manager, verification leads |
    | Shared verification evidence | Verification lead | Requirement owner, safety engineer, QA |
    | ISO-specific safety analyses | Functional safety organization | SYS/SWE/HWE architects and domain experts |
    | ASPICE capability evidence | Process Quality Lead | Project Manager, process owners, QA |
    | Baselines and approval history | Configuration Manager / Document Controller | Artifact owner and designated approvers |

    ## Project-start actions

    1. Assign a single owner and source location for every row marked Shared.
    2. Add ISO attributes to the existing Redmine requirement and test fields instead of creating duplicate issues.
    3. Link safety analyses to the affected SYS, SWE, and HWE issue IDs.
    4. Use the same test result as evidence only when configuration, environment, and acceptance criteria match both objectives.
    5. Review this crosswalk at each baseline and whenever scope, ASIL, supplier allocation, or assessment scope changes.

    ## Review and approval record

    | Revision | Date | Author | Reviewer | Approver | Summary |
    | --- | --- | --- | --- | --- | --- |
    | 0.1 | TBD | ModuleX Demo | TBD | TBD | Initial integrated-framework crosswalk |
  MARKDOWN
end

project = Project.find_by!(identifier: PROJECT_IDENTIFIER)
author = User.find_by(login: "aspice.author") || User.active.where(admin: true).first
User.current = author
file = DmsfFile.find_by(project_id: project.id, dmsf_folder_id: nil, name: FILENAME, deleted: 0)

if file
  puts "FILE=#{file.name}"
  puts "CREATED=0"
  exit
end

content = crosswalk_content
file = DmsfFile.create!(project: project, dmsf_folder_id: nil, name: FILENAME, deleted: 0)
revision = DmsfFileRevision.new(
  dmsf_file: file, name: FILENAME, title: TITLE,
  description: "Integrated ISO 26262 and Automotive SPICE work-product relationship and reuse guidance.",
  major_version: 0, minor_version: 1, size: content.bytesize, mime_type: "text/markdown",
  digest: Digest::MD5.hexdigest(content), deleted: 0, user: author
)
revision.disk_filename = revision.new_storage_filename
revision.save!
FileUtils.mkdir_p(File.dirname(revision.disk_file(search_if_not_exists: false)))
File.binwrite(revision.disk_file(search_if_not_exists: false), content)

puts "FILE=#{file.name}"
puts "ROWS=#{CROSSWALK.size}"
puts "CREATED=1"

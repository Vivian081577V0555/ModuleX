# frozen_string_literal: true

# Run inside the enterprise-demo Redmine container:
#   bundle exec rails runner /tmp/seed_iso26262_documents.rb RAILS_ENV=production
require "digest"
require "fileutils"

PROJECT_IDENTIFIER = "aspice-requirements"
ROOT_FOLDER = "ISO 26262 - 48V Auxiliary Battery Safety"

FOLDERS = [
  ["00_Project_Entry", "Project entry, tailoring, document register, and traceability planning."],
  ["01_Project_Management_Part_2", "Functional safety management and confirmation measures."],
  ["02_Concept_Phase_Part_3", "Item definition, HARA, safety goals, and functional safety concept."],
  ["03_System_Level_Part_4", "Technical safety concept, architecture, integration, and validation."],
  ["04_Hardware_Level_Part_5", "Hardware safety requirements, analyses, design, and verification."],
  ["05_Software_Level_Part_6", "Software safety requirements, architecture, analyses, and verification."],
  ["06_Production_Operation_Service_Part_7", "Production, operation, service, field monitoring, and decommissioning."],
  ["07_Supporting_Processes_Part_8", "Configuration, change, tools, suppliers, documentation, and problem resolution."],
  ["08_Safety_Analysis_and_Case_Part_9", "Dependent failure analysis, safety analyses, and the safety case."],
  ["09_Released_Baselines", "Approved and released baselines. Working drafts remain in their lifecycle folders."]
].freeze

DOCUMENTS = [
  ["00_Project_Entry", "DOC-001", "Document Register and Deliverable Index", "Functional Safety Manager", "Project Kickoff", "Master list of required work products, owners, status, versions, reviews, and release evidence.", ["Scope and applicability", "Deliverable register", "Owner and reviewer matrix", "Baseline and release status", "Open gaps and actions"]],
  ["00_Project_Entry", "DOC-002", "Safety Lifecycle Tailoring and Compliance Matrix", "Functional Safety Manager", "Project Kickoff", "Defines ISO 26262 applicability, ASIL tailoring, work-product mapping, and justified exclusions.", ["Item assumptions", "Applicable clauses and parts", "Tailoring decisions", "Compliance evidence mapping", "Approval"]],
  ["00_Project_Entry", "DOC-003", "Safety Traceability Matrix", "Safety Architect", "Safety Case Release", "Maintains bidirectional links from hazards and safety goals through requirements, design, tests, and evidence.", ["Trace identifier rules", "Hazard to safety-goal links", "FSC to TSR links", "HSR and SSR allocation", "Verification evidence", "Coverage gaps"]],

  ["01_Project_Management_Part_2", "DOC-201", "Safety Plan", "Functional Safety Manager", "Project Kickoff", "Defines lifecycle activities, schedule, ASIL tailoring, responsibilities, reviews, audits, and release gates.", ["Item and project scope", "Lifecycle and milestones", "Safety activities", "Roles and independence", "Deliverables", "Confirmation measures", "Escalation and reporting"]],
  ["01_Project_Management_Part_2", "DOC-202", "Safety Organization RACI and Competence Records", "Functional Safety Manager", "Project Kickoff", "Records role assignments, independence, competence criteria, training, and authorization.", ["Safety organization", "RACI", "Competence criteria", "Training records", "Independence", "Approval authority"]],
  ["01_Project_Management_Part_2", "DOC-203", "Confirmation Measures Plan", "Functional Safety Manager", "Concept Freeze", "Plans confirmation reviews, functional safety audits, and functional safety assessment with required independence.", ["Confirmation scope", "Reviewer independence", "Review schedule", "Audit plan", "Assessment plan", "Finding closure"]],

  ["02_Concept_Phase_Part_3", "DOC-301", "Item Definition", "System Safety Engineer", "Concept Freeze", "Defines the 48V battery, BMS, AFE, contactors, interlock, power and CAN interfaces, environment, boundaries, and assumptions.", ["Purpose and vehicle context", "System boundary", "Functions and operating modes", "Interfaces", "Environmental assumptions", "Known dependencies"]],
  ["02_Concept_Phase_Part_3", "DOC-302", "HARA Report", "System Safety Engineer", "Concept Freeze", "Evaluates hazards such as thermal runaway, loss of auxiliary power, unintended energization, contactor faults, and communication loss.", ["Operational situations", "Malfunctions and hazards", "Severity exposure controllability", "ASIL classification", "Rationale", "Verification and review record"]],
  ["02_Concept_Phase_Part_3", "DOC-303", "Safety Goals", "Safety Architect", "Concept Freeze", "Defines uniquely identified safety goals, safe states, fault tolerant time intervals, ASIL, and acceptance rationale.", ["Safety goal register", "Hazard references", "Safe states", "FTTI", "ASIL", "Verification criteria"]],
  ["02_Concept_Phase_Part_3", "DOC-304", "Functional Safety Concept", "Safety Architect", "Concept Freeze", "Allocates functional safety requirements to the item and external measures and defines degraded modes and driver warnings.", ["Functional safety requirements", "Allocation", "Safe-state strategy", "Degraded operation", "External measures", "Traceability"]],

  ["03_System_Level_Part_4", "DOC-401", "Technical Safety Requirements Specification", "System Safety Engineer", "System Safety Baseline", "Defines measurable technical safety requirements, diagnostic coverage expectations, timing, and reactions.", ["Derived TSRs", "ASIL and attributes", "Timing and FTTI", "Diagnostic reactions", "Interface requirements", "Verification criteria", "Traceability"]],
  ["03_System_Level_Part_4", "DOC-402", "Technical Safety Concept", "Safety Architect", "System Safety Baseline", "Allocates TSRs to hardware, software, and external elements and explains safety mechanisms and independence.", ["System decomposition", "TSR allocation", "Safety mechanisms", "Freedom from interference", "Redundancy and independence", "Interface assumptions"]],
  ["03_System_Level_Part_4", "DOC-403", "System Architecture and Interface Design", "System Architect", "System Safety Baseline", "Describes MCU, AFE, contactors, interlock, power, sensors, CAN communication, and diagnostic architecture.", ["Architecture views", "Hardware software interface", "CAN interface", "Power and grounding", "Interlock and contactors", "Diagnostics", "Design rationale"]],
  ["03_System_Level_Part_4", "DOC-404", "System Safety Analysis Report", "Safety Analyst", "System Safety Baseline", "Provides system FMEA and FTA evidence and demonstrates consistency with HARA, FSC, and TSRs.", ["Analysis scope", "System FMEA", "Fault trees", "Safety mechanism effectiveness", "Single and multiple point faults", "Actions and closure"]],
  ["03_System_Level_Part_4", "DOC-405", "System Integration and Verification Plan and Report", "System Verification Lead", "HW SW Integration", "Defines and records system integration, fault injection, HIL, timing, communication, and robustness tests.", ["Verification strategy", "Environment and configuration", "Test specifications", "Fault injection", "Results and anomalies", "Coverage and conclusion"]],
  ["03_System_Level_Part_4", "DOC-406", "Safety Validation Plan and Report", "Independent Safety Validator", "Safety Validation", "Validates safety goals at vehicle or representative system level under normal, boundary, and fault conditions.", ["Validation scope", "Independence", "Vehicle use cases", "Fault scenarios", "Acceptance criteria", "Results", "Residual risk conclusion"]],

  ["04_Hardware_Level_Part_5", "DOC-501", "Hardware Safety Requirements Specification", "Hardware Safety Engineer", "System Safety Baseline", "Allocates hardware safety requirements to MCU, AFE, sensors, power supply, contactors, and watchdogs.", ["HSR register", "ASIL attributes", "Interface constraints", "Diagnostics", "Environmental limits", "Verification criteria", "Traceability"]],
  ["04_Hardware_Level_Part_5", "DOC-502", "Hardware Architecture and Detailed Design", "Hardware Lead", "HW SW Integration", "Documents safety-related circuits, component selection, derating, diagnostic paths, and design rationale.", ["Architecture", "Schematics and interfaces", "Component assumptions", "Safety mechanisms", "Derating", "Design review record"]],
  ["04_Hardware_Level_Part_5", "DOC-503", "FMEDA Report", "Hardware Safety Engineer", "HW SW Integration", "Quantifies failure modes, diagnostic coverage, SPFM, LFM, and PMHF with data sources and assumptions.", ["FMEDA scope", "Failure-rate sources", "Failure modes", "Diagnostic coverage", "SPFM and LFM", "PMHF", "Sensitivity and conclusions"]],
  ["04_Hardware_Level_Part_5", "DOC-504", "Hardware Dependent Failure Analysis", "Safety Analyst", "HW SW Integration", "Assesses common-cause and cascading failures, shared resources, environmental coupling, and independence claims.", ["Dependency candidates", "Common-cause failures", "Cascading failures", "Shared resources", "Independence evidence", "Mitigations"]],
  ["04_Hardware_Level_Part_5", "DOC-505", "Hardware Verification Plan and Report", "Hardware Verification Lead", "HW SW Integration", "Records analysis, inspection, environmental, electrical, diagnostic, and fault-injection verification of HSRs.", ["Verification methods", "Test setup", "Requirement coverage", "Boundary tests", "Fault injection", "Results and anomalies", "Conclusion"]],

  ["05_Software_Level_Part_6", "DOC-601", "Software Safety Requirements Specification", "Software Safety Engineer", "System Safety Baseline", "Defines software safety requirements, timing, data integrity, diagnostics, communication, and safe-state behavior.", ["SSR register", "ASIL and attributes", "Timing", "Data and control flow", "Diagnostics", "Verification criteria", "Traceability"]],
  ["05_Software_Level_Part_6", "DOC-602", "Software Architecture and Unit Design", "Software Architect", "HW SW Integration", "Documents components, interfaces, scheduling, memory, FFI, defensive design, and safety mechanisms.", ["Architecture", "Component interfaces", "Scheduling and timing", "Memory and data integrity", "Freedom from interference", "Unit design", "Design rationale"]],
  ["05_Software_Level_Part_6", "DOC-603", "Software Safety Analysis Report", "Software Safety Engineer", "HW SW Integration", "Analyzes software failure modes, dependent failures, timing faults, data corruption, and safety mechanism effectiveness.", ["Analysis scope", "Software FMEA", "Dependent failures", "Timing and concurrency", "Data corruption", "Actions and closure"]],
  ["05_Software_Level_Part_6", "DOC-604", "Software Verification Plan and Report", "Software Verification Lead", "HW SW Integration", "Combines reviews, static analysis, unit tests, integration tests, coverage, fault injection, and anomaly disposition.", ["Verification strategy", "Review and static analysis", "Unit tests", "Integration tests", "Structural coverage", "Fault injection", "Results and anomalies"]],

  ["06_Production_Operation_Service_Part_7", "DOC-701", "Production Control and End of Line Test Plan", "Manufacturing Quality Lead", "Safety Validation", "Controls safety-relevant production characteristics, programming, calibration, traceability, and end-of-line testing.", ["Production controls", "Special characteristics", "Programming and calibration", "End-of-line tests", "Nonconformance handling", "Production records"]],
  ["06_Production_Operation_Service_Part_7", "DOC-702", "Operation Service Emergency and Decommissioning Manual", "Service Safety Lead", "Safety Case Release", "Defines intended use, warnings, diagnostics, service precautions, emergency handling, transport, storage, and decommissioning.", ["Operational constraints", "Warning and diagnostics", "Service procedures", "Emergency response", "Transport and storage", "Decommissioning and recycling"]],
  ["06_Production_Operation_Service_Part_7", "DOC-703", "Field Monitoring and Safety Anomaly Response Plan", "Product Safety Manager", "Safety Case Release", "Defines field-data collection, safety anomaly triage, escalation, corrective actions, and post-release monitoring.", ["Monitoring sources", "Safety event criteria", "Triage and escalation", "Regulatory communication", "Corrective actions", "Effectiveness review"]],

  ["07_Supporting_Processes_Part_8", "DOC-801", "Configuration Change and Baseline Management Plan", "Configuration Manager", "Project Kickoff", "Controls configuration items, change impact analysis, approvals, baselines, releases, and reproducibility.", ["Configuration items", "Branch and version rules", "Change control", "Safety impact analysis", "Baseline approval", "Release records"]],
  ["07_Supporting_Processes_Part_8", "DOC-802", "Documentation Management and Review Procedure", "Document Controller", "Project Kickoff", "Defines document identifiers, templates, review workflow, signatures, versioning, retention, and archival.", ["Document classes", "Identification rules", "Author review approval", "Version and status", "Retention", "Access and archival"]],
  ["07_Supporting_Processes_Part_8", "DOC-803", "Tool Confidence and Qualification Plan", "Tool Qualification Lead", "System Safety Baseline", "Classifies safety-related tools, evaluates tool impact and error detection, and records qualification evidence.", ["Tool inventory", "Use cases", "Tool impact", "Error detection", "Confidence level", "Qualification method", "Evidence"]],
  ["07_Supporting_Processes_Part_8", "DOC-804", "Supplier Safety Interface and Development Interface Agreement", "Supplier Manager", "Project Kickoff", "Defines distributed-development responsibilities, assumptions, exchanged work products, reviews, and acceptance criteria.", ["Supplier scope", "Safety responsibilities", "Assumptions and dependencies", "Work-product exchange", "Review and acceptance", "Escalation"]],
  ["07_Supporting_Processes_Part_8", "DOC-805", "Safety Anomaly and Problem Resolution Log", "Quality Assurance", "Safety Case Release", "Tracks safety anomalies from discovery through analysis, impact assessment, correction, verification, and closure.", ["Problem register", "Safety impact", "Root cause", "Containment and correction", "Verification", "Closure approval"]],

  ["08_Safety_Analysis_and_Case_Part_9", "DOC-901", "Cross Level Dependent Failure Analysis", "Safety Analyst", "Safety Validation", "Consolidates cross-domain common-cause, cascading, shared-resource, and coexistence analyses.", ["Analysis scope", "Cross-domain dependencies", "Common-cause failures", "Cascading failures", "Coexistence and FFI", "Mitigations and evidence"]],
  ["08_Safety_Analysis_and_Case_Part_9", "DOC-902", "Safety Case Report", "Functional Safety Manager", "Safety Case Release", "Presents the structured argument that the 48V auxiliary battery item achieves acceptable functional safety.", ["Top-level safety claim", "Argument structure", "Evidence index", "Assumptions and limitations", "Residual risks", "Open issues", "Release conclusion"]],
  ["08_Safety_Analysis_and_Case_Part_9", "DOC-903", "Confirmation Review Audit and Assessment Reports", "Independent Safety Assessor", "Safety Case Release", "Collects independent confirmation review, audit, and functional safety assessment findings and closure evidence.", ["Independence statement", "Review reports", "Audit report", "Assessment report", "Findings", "Closure evidence", "Recommendation"]]
].freeze

MILESTONES = [
  "Project Kickoff", "Concept Freeze", "System Safety Baseline",
  "HW SW Integration", "Safety Validation", "Safety Case Release"
].freeze

def ensure_folder(project, parent, title, description, author)
  folder = DmsfFolder.find_or_initialize_by(
    project_id: project.id,
    dmsf_folder_id: parent&.id,
    title: title
  )
  folder.description = description
  folder.user_id = author.id
  folder.notification = false
  folder.deleted = false
  folder.save!
  folder
end

def template_content(document)
  _folder, id, title, owner, milestone, purpose, sections = document
  section_text = sections.map.with_index(1) { |section, index| "## #{index}. #{section}\n\nTBD\n" }.join("\n")
  register = if id == "DOC-001"
               rows = DOCUMENTS.map do |folder, document_id, document_title, document_owner, target, _summary, _sections|
                 "| #{document_id} | #{document_title} | #{folder} | #{document_owner} | #{target} | Draft |"
               end.join("\n")
               <<~REGISTER

                 ## Initial controlled-document register

                 | ID | Document | Folder | Owner role | Target milestone | Initial status |
                 | --- | --- | --- | --- | --- | --- |
                 #{rows}
               REGISTER
             else
               ""
             end
  <<~MARKDOWN
    # [#{id}] #{title}

    | Field | Value |
    | --- | --- |
    | Document ID | #{id} |
    | Status | Draft |
    | Version | 0.1 |
    | Owner role | #{owner} |
    | Target milestone | #{milestone} |
    | Safety classification | To be assigned |
    | Reviewer / approver | To be assigned per Safety Plan |

    ## Purpose

    #{purpose}

    #{register}

    ## Referenced inputs

    - ISO 26262:2018 applicable clauses and work products
    - Approved upstream safety work products
    - 48V auxiliary battery/BMS project assumptions and interfaces

    #{section_text}
    ## Review and approval record

    | Revision | Date | Author | Reviewer | Approver | Summary |
    | --- | --- | --- | --- | --- | --- |
    | 0.1 | TBD | TBD | TBD | TBD | Initial project template |
  MARKDOWN
end

def ensure_document(project, folder, author, document, content)
  _folder, id, title, _owner, _milestone, _purpose, _sections = document
  filename = "#{id}_#{title.gsub(/[^A-Za-z0-9]+/, '_').gsub(/_+/, '_').sub(/_$/, '')}.md"
  file = DmsfFile.find_by(
    project_id: project.id,
    dmsf_folder_id: folder.id,
    name: filename,
    deleted: DmsfFile::STATUS_ACTIVE
  )
  return [file, false] if file

  file = DmsfFile.create!(project: project, dmsf_folder: folder, name: filename, deleted: DmsfFile::STATUS_ACTIVE)
  revision = DmsfFileRevision.new(
    dmsf_file: file,
    name: filename,
    title: "[#{id}] #{title}",
    description: "ISO 26262 project-start template for the 48V auxiliary battery/BMS safety lifecycle.",
    major_version: 0,
    minor_version: 1,
    size: content.bytesize,
    mime_type: "text/markdown",
    digest: Digest::MD5.hexdigest(content),
    deleted: DmsfFileRevision::STATUS_ACTIVE,
    user: author
  )
  revision.disk_filename = revision.new_storage_filename
  revision.save!
  FileUtils.mkdir_p(File.dirname(revision.disk_file(search_if_not_exists: false)))
  File.binwrite(revision.disk_file(search_if_not_exists: false), content)
  [file, true]
end

project = Project.find_by!(identifier: PROJECT_IDENTIFIER)
author = User.find_by(login: "aspice.author") || User.active.where(admin: true).first
User.current = author

root = ensure_folder(
  project, nil, ROOT_FOLDER,
  "ISO 26262:2018 functional-safety work products for a 48V auxiliary battery and BMS item.",
  author
)
folders = FOLDERS.to_h do |title, description|
  [title, ensure_folder(project, root, title, description, author)]
end

MILESTONES.each do |name|
  version = Version.find_or_initialize_by(project: project, name: "ISO26262 - #{name}")
  version.status = "open" if version.new_record?
  version.description = "ISO 26262 48V auxiliary battery safety lifecycle milestone."
  version.save!
end

created = 0
DOCUMENTS.each do |document|
  _file, was_created = ensure_document(
    project, folders.fetch(document[0]), author, document, template_content(document)
  )
  created += 1 if was_created
end

puts "ROOT=#{root.title}"
puts "FOLDERS=#{folders.size + 1}"
puts "DOCUMENTS=#{DOCUMENTS.size}"
puts "CREATED=#{created}"
puts "MILESTONES=#{MILESTONES.size}"

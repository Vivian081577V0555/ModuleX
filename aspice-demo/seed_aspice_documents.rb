# frozen_string_literal: true

# Run inside the enterprise-demo Redmine container:
#   bundle exec rails runner /tmp/seed_aspice_documents.rb RAILS_ENV=production
require "digest"
require "fileutils"

PROJECT_IDENTIFIER = "aspice-requirements"
ROOT_FOLDER = "Automotive SPICE 4.0 - Project Work Products"

FOLDERS = [
  ["00_Project_Entry_and_Assessment", "Scope, tailoring, work-product register, traceability, and assessment readiness."],
  ["01_MAN_3_Project_Management", "Project planning, estimates, monitoring, risks, and corrective actions."],
  ["02_SYS_System_Engineering", "SYS.1 through SYS.5 system engineering work products."],
  ["03_SWE_Software_Engineering", "SWE.1 through SWE.6 software engineering work products."],
  ["04_HWE_Hardware_Engineering", "HWE.1 through HWE.4 hardware engineering work products."],
  ["05_SUP_Supporting_Processes", "SUP.1, SUP.8, SUP.9, and SUP.10 evidence."],
  ["06_ACQ_4_Supplier_Monitoring", "Supplier agreements, exchanges, reviews, progress, and corrective actions."],
  ["07_Process_Capability_CL2_CL3", "Managed and established process evidence for capability levels 2 and 3."],
  ["08_Released_Baselines", "Approved baselines and release packages; working drafts remain in process folders."]
].freeze

DOCUMENTS = [
  ["00_Project_Entry_and_Assessment", "ASP-001", "Process Scope and Tailoring Matrix", "Process Owner", "Project Kickoff", "Defines the PAM 4.0 processes in scope, applicability, tailoring decisions, target capability, and rationale.", ["Project and product scope", "Process applicability", "Target capability levels", "Tailoring decisions", "Roles and approvals"]],
  ["00_Project_Entry_and_Assessment", "ASP-002", "Work Product Register and Evidence Index", "Project Quality Lead", "Assessment Readiness", "Master index of work products, owners, baselines, reviews, objective evidence, and assessment status.", ["Work-product register", "Owner and reviewer matrix", "Baseline status", "Evidence locations", "Open gaps"]],
  ["00_Project_Entry_and_Assessment", "ASP-003", "Bidirectional Traceability and Consistency Matrix", "Requirements Lead", "Release Candidate", "Shows consistency and bidirectional traceability across requirements, architecture, implementation, verification measures, and results.", ["Trace model", "SYS links", "SWE links", "HWE links", "Verification coverage", "Consistency findings"]],
  ["00_Project_Entry_and_Assessment", "ASP-004", "Assessment Readiness and Evidence Checklist", "Process Quality Lead", "Assessment Readiness", "Maps process outcomes, base practices, and expected information items to available project evidence.", ["Assessment scope", "Interview plan", "Evidence mapping", "Sample selection", "Gaps and actions", "Readiness decision"]],

  ["01_MAN_3_Project_Management", "MAN3-001", "Project Management Plan", "Project Manager", "Project Kickoff", "Defines lifecycle, organization, interfaces, milestones, deliverables, resources, communication, and control mechanisms.", ["Scope and objectives", "Lifecycle and milestones", "Organization", "Deliverables", "Resources", "Communication", "Control and escalation"]],
  ["01_MAN_3_Project_Management", "MAN3-002", "Estimation Schedule and Resource Baseline", "Project Manager", "Project Kickoff", "Records size, effort, cost, resource, dependency, and schedule estimates with assumptions.", ["Estimation method", "Assumptions", "Work breakdown", "Resources", "Schedule baseline", "Re-estimation history"]],
  ["01_MAN_3_Project_Management", "MAN3-003", "Project Monitoring and Status Reports", "Project Manager", "Release Candidate", "Compares actual progress, quality, cost, and resources against plan and tracks corrective actions.", ["Milestone status", "Effort and schedule", "Quality status", "Dependencies", "Corrective actions", "Decisions"]],
  ["01_MAN_3_Project_Management", "MAN3-004", "Risk Register and Mitigation Plan", "Project Manager", "Release Candidate", "Identifies, analyzes, prioritizes, monitors, and mitigates project and technical risks.", ["Risk criteria", "Risk register", "Probability and impact", "Mitigation", "Contingency", "Review history"]],
  ["01_MAN_3_Project_Management", "MAN3-005", "Project Review and Decision Log", "Project Manager", "Release Candidate", "Records management reviews, commitments, decisions, action owners, due dates, and closure evidence.", ["Review calendar", "Participants", "Inputs", "Decisions", "Actions", "Closure"]],

  ["02_SYS_System_Engineering", "SYS1-001", "Stakeholder Requirements Specification", "Requirements Engineer", "Requirements Baseline", "Captures agreed stakeholder needs, constraints, interfaces, acceptance expectations, and communication evidence.", ["Stakeholders", "Needs and constraints", "Operational scenarios", "Interfaces", "Acceptance expectations", "Agreement record"]],
  ["02_SYS_System_Engineering", "SYS2-001", "System Requirements Specification", "System Requirements Lead", "Requirements Baseline", "Defines analyzed, structured, prioritized, feasible, verifiable system requirements and attributes.", ["System requirements", "Attributes and priority", "Feasibility analysis", "Interfaces", "Verification criteria", "Traceability"]],
  ["02_SYS_System_Engineering", "SYS3-001", "System Architecture Design", "System Architect", "Architecture Baseline", "Allocates requirements to system elements and defines interfaces, behavior, rationale, and architectural analyses.", ["Architecture views", "Element allocation", "Interfaces", "Dynamic behavior", "Resource budgets", "Architecture evaluation", "Traceability"]],
  ["02_SYS_System_Engineering", "SYS4-001", "System Integration and Integration Verification Plan", "System Integration Lead", "Integration Complete", "Defines integration sequence, verification measures, selection and regression criteria, environments, and entry/exit criteria.", ["Integration strategy", "Verification measures", "Selection criteria", "Environment", "Entry and exit criteria", "Traceability"]],
  ["02_SYS_System_Engineering", "SYS4-002", "System Integration and Integration Verification Report", "System Integration Lead", "Integration Complete", "Records integrated configurations, execution data, results, anomalies, coverage, and communicated conclusions.", ["Integrated baseline", "Execution record", "Results", "Anomalies", "Coverage", "Conclusion"]],
  ["02_SYS_System_Engineering", "SYS5-001", "System Verification Plan", "System Verification Lead", "Release Candidate", "Defines system-requirement verification measures, pass/fail criteria, selection, regression, infrastructure, and coverage.", ["Verification strategy", "Measures", "Selection and regression", "Environment", "Acceptance criteria", "Traceability"]],
  ["02_SYS_System_Engineering", "SYS5-002", "System Verification Report", "System Verification Lead", "Release Candidate", "Records system verification results, output data, anomalies, coverage, summary, and communication evidence.", ["Verified baseline", "Execution results", "Output data", "Anomalies", "Coverage", "Summary and release recommendation"]],

  ["03_SWE_Software_Engineering", "SWE1-001", "Software Requirements Specification", "Software Requirements Lead", "Requirements Baseline", "Defines structured, analyzed, prioritized, feasible, verifiable software requirements and operating impacts.", ["Software requirements", "Attributes", "Feasibility", "Operating environment", "Verification criteria", "Traceability"]],
  ["03_SWE_Software_Engineering", "SWE2-001", "Software Architecture Design", "Software Architect", "Architecture Baseline", "Defines software elements, interfaces, behavior, resource consumption, allocation, and architecture evaluation.", ["Architecture views", "Elements and interfaces", "Behavior", "Resource budgets", "Allocation", "Architecture evaluation", "Traceability"]],
  ["03_SWE_Software_Engineering", "SWE3-001", "Software Detailed Design and Unit Construction", "Software Development Lead", "Unit Complete", "Documents unit interfaces, detailed logic, data structures, construction standards, source baseline, and consistency.", ["Unit decomposition", "Detailed design", "Interfaces", "Data structures", "Construction rules", "Source references", "Traceability"]],
  ["03_SWE_Software_Engineering", "SWE4-001", "Software Unit Verification Plan and Specification", "Software Unit Verification Lead", "Unit Complete", "Defines static and dynamic unit verification measures, coverage objectives, selection, and regression criteria.", ["Verification strategy", "Static analysis", "Unit tests", "Coverage criteria", "Regression selection", "Environment", "Traceability"]],
  ["03_SWE_Software_Engineering", "SWE4-002", "Software Unit Verification Report", "Software Unit Verification Lead", "Unit Complete", "Records unit verification results, coverage data, anomalies, and summarized conclusions.", ["Verified units", "Static-analysis results", "Test results", "Coverage", "Anomalies", "Conclusion"]],
  ["03_SWE_Software_Engineering", "SWE5-001", "Software Component Integration Verification Plan", "Software Integration Lead", "Integration Complete", "Defines component integration sequence and verification measures against software architecture and interfaces.", ["Integration sequence", "Component baselines", "Verification measures", "Selection and regression", "Environment", "Traceability"]],
  ["03_SWE_Software_Engineering", "SWE5-002", "Software Component Integration Verification Report", "Software Integration Lead", "Integration Complete", "Records integrated software configurations, results, anomalies, coverage, and conclusions.", ["Integrated baseline", "Execution record", "Results", "Anomalies", "Coverage", "Conclusion"]],
  ["03_SWE_Software_Engineering", "SWE6-001", "Software Verification Plan", "Software Verification Lead", "Release Candidate", "Defines software-requirement verification measures, selection, regression, infrastructure, and acceptance criteria.", ["Verification strategy", "Measures", "Selection criteria", "Environment", "Acceptance criteria", "Traceability"]],
  ["03_SWE_Software_Engineering", "SWE6-002", "Software Verification and Release Report", "Software Verification Lead", "Release Candidate", "Records software verification results, anomalies, coverage, release content, known limitations, and recommendation.", ["Verified baseline", "Results", "Anomalies", "Coverage", "Release content", "Known limitations", "Recommendation"]],

  ["04_HWE_Hardware_Engineering", "HWE1-001", "Hardware Requirements Specification", "Hardware Requirements Lead", "Requirements Baseline", "Defines structured, analyzed, feasible hardware requirements and consistency with system requirements and architecture.", ["Hardware requirements", "Attributes", "Feasibility", "Operating impact", "Verification criteria", "Traceability"]],
  ["04_HWE_Hardware_Engineering", "HWE2-001", "Hardware Design and Production Data", "Hardware Lead", "Architecture Baseline", "Defines hardware architecture, detailed design, interfaces, components, production data, and design rationale.", ["Architecture", "Detailed design", "Interfaces", "Components", "Production data", "Design evaluation", "Traceability"]],
  ["04_HWE_Hardware_Engineering", "HWE3-001", "Hardware Design Verification Plan and Report", "Hardware Verification Lead", "Integration Complete", "Defines and records verification against hardware design using reviews, analyses, simulations, and measurements.", ["Verification measures", "Selection criteria", "Design baseline", "Results", "Anomalies", "Coverage", "Conclusion"]],
  ["04_HWE_Hardware_Engineering", "HWE4-001", "Hardware Requirements Verification Plan and Report", "Hardware Verification Lead", "Release Candidate", "Defines and records verification of compliant hardware samples against hardware requirements.", ["Compliant samples", "Verification measures", "Selection and regression", "Results", "Anomalies", "Coverage", "Conclusion"]],

  ["05_SUP_Supporting_Processes", "SUP1-001", "Quality Assurance Plan and Reports", "Quality Assurance", "Assessment Readiness", "Plans independent quality assurance, evaluates process and work-product compliance, reports findings, and verifies closure.", ["QA scope", "Independence", "Planned evaluations", "Findings", "Escalation", "Closure evidence", "Summary"]],
  ["05_SUP_Supporting_Processes", "SUP8-001", "Configuration Management Plan and Status Records", "Configuration Manager", "Project Kickoff", "Defines configuration items, branching, change control, baselines, status accounting, audits, releases, and recovery.", ["CM strategy", "Configuration items", "Version control", "Baseline management", "Status accounting", "Audits", "Release and recovery"]],
  ["05_SUP_Supporting_Processes", "SUP9-001", "Problem Resolution Register", "Problem Manager", "Release Candidate", "Records problems, classification, analysis, impact, resolution, verification, trend analysis, and closure.", ["Problem criteria", "Problem register", "Impact analysis", "Resolution", "Verification", "Status and trends", "Closure"]],
  ["05_SUP_Supporting_Processes", "SUP10-001", "Change Request Register and Impact Analysis", "Change Control Manager", "Release Candidate", "Controls change requests from recording through impact analysis, approval, implementation, verification, and closure.", ["Change register", "Impact analysis", "Approval", "Implementation links", "Verification", "Status and closure"]],
  ["05_SUP_Supporting_Processes", "SUP-002", "Review Records and Communication Evidence", "Project Quality Lead", "Assessment Readiness", "Collects review minutes, participants, findings, decisions, actions, communication, and closure evidence.", ["Review plan", "Review records", "Findings", "Decisions", "Communication", "Action closure"]],

  ["06_ACQ_4_Supplier_Monitoring", "ACQ4-001", "Supplier Joint Agreement and Interface Matrix", "Supplier Manager", "Project Kickoff", "Defines joint activities, interfaces, responsibilities, exchanged information, communication, reviews, and escalation.", ["Supplier scope", "Joint activities", "Interfaces", "Responsibilities", "Information exchange", "Review cadence", "Escalation"]],
  ["06_ACQ_4_Supplier_Monitoring", "ACQ4-002", "Supplier Monitoring and Corrective Action Report", "Supplier Manager", "Release Candidate", "Tracks supplier work-product reviews, progress, quality, risks, deviations, and corrective actions to closure.", ["Progress status", "Work-product reviews", "Quality and risks", "Deviations", "Corrective actions", "Closure"]],

  ["07_Process_Capability_CL2_CL3", "PA2-001", "Process Performance Objectives and Management Records", "Process Owner", "Assessment Readiness", "Provides PA 2.1 evidence for objectives, planning, monitoring, responsibilities, resources, interfaces, and corrective action.", ["Performance objectives", "Plans", "Monitoring", "Responsibilities", "Resources", "Interfaces", "Corrective actions"]],
  ["07_Process_Capability_CL2_CL3", "PA2-002", "Work Product Management and Control Records", "Process Owner", "Assessment Readiness", "Provides PA 2.2 evidence for work-product requirements, controls, identification, reviews, and adjustment.", ["Work-product requirements", "Identification", "Control", "Review criteria", "Review records", "Adjustments"]],
  ["07_Process_Capability_CL2_CL3", "PA3-001", "Standard Process Description and Tailoring Guideline", "Organizational Process Owner", "Assessment Readiness", "Provides PA 3.1 evidence for a defined standard process, interactions, roles, infrastructure, methods, and tailoring.", ["Standard process", "Process interactions", "Roles and competencies", "Infrastructure", "Methods and tools", "Tailoring guideline"]],
  ["07_Process_Capability_CL2_CL3", "PA3-002", "Process Deployment and Effectiveness Evidence", "Project Process Owner", "Assessment Readiness", "Provides PA 3.2 evidence that the tailored process is deployed with resources, competencies, data, and improvement feedback.", ["Deployed process", "Role assignments", "Competence evidence", "Resources", "Performance data", "Experience and improvement"]]
].freeze

MILESTONES = [
  "Project Kickoff", "Requirements Baseline", "Architecture Baseline", "Unit Complete",
  "Integration Complete", "Release Candidate", "Assessment Readiness"
].freeze

def ensure_folder(project, parent, title, description, author)
  folder = DmsfFolder.find_or_initialize_by(project_id: project.id, dmsf_folder_id: parent&.id, title: title)
  folder.description = description
  folder.user_id = author.id
  folder.notification = false
  folder.deleted = false
  folder.save!
  folder
end

def template_content(document)
  folder, id, title, owner, milestone, purpose, sections = document
  body = sections.map.with_index(1) { |section, index| "## #{index}. #{section}\n\nTBD\n" }.join("\n")
  register = if id == "ASP-002"
               rows = DOCUMENTS.map { |f, i, t, o, m, _p, _s| "| #{i} | #{t} | #{f} | #{o} | #{m} | Draft |" }.join("\n")
               "\n## Initial work-product register\n\n| ID | Work product | Folder | Owner | Milestone | Status |\n| --- | --- | --- | --- | --- | --- |\n#{rows}\n"
             else
               ""
             end
  <<~MARKDOWN
    # [#{id}] #{title}

    | Field | Value |
    | --- | --- |
    | Process / evidence ID | #{id} |
    | Status | Draft |
    | Version | 0.1 |
    | Owner role | #{owner} |
    | Target milestone | #{milestone} |
    | PAM baseline | Automotive SPICE 4.0 |
    | Reviewer / approver | To be assigned |

    ## Purpose

    #{purpose}
    #{register}
    ## Inputs and traceability

    - Applicable upstream work products and approved baselines
    - Related Redmine issue IDs and bidirectional relations
    - Review, agreement, and communication evidence

    #{body}
    ## Review and approval record

    | Revision | Date | Author | Reviewer | Approver | Summary |
    | --- | --- | --- | --- | --- | --- |
    | 0.1 | TBD | TBD | TBD | TBD | Initial project template |
  MARKDOWN
end

def ensure_document(project, folder, author, document)
  _folder, id, title, _owner, _milestone, _purpose, _sections = document
  filename = "#{id}_#{title.gsub(/[^A-Za-z0-9]+/, '_').gsub(/_+/, '_').sub(/_$/, '')}.md"
  file = DmsfFile.find_by(project_id: project.id, dmsf_folder_id: folder.id, name: filename, deleted: 0)
  return false if file

  content = template_content(document)
  file = DmsfFile.create!(project: project, dmsf_folder: folder, name: filename, deleted: 0)
  revision = DmsfFileRevision.new(
    dmsf_file: file, name: filename, title: "[#{id}] #{title}",
    description: "Automotive SPICE 4.0 project-start work-product template.",
    major_version: 0, minor_version: 1, size: content.bytesize, mime_type: "text/markdown",
    digest: Digest::MD5.hexdigest(content), deleted: 0, user: author
  )
  revision.disk_filename = revision.new_storage_filename
  revision.save!
  FileUtils.mkdir_p(File.dirname(revision.disk_file(search_if_not_exists: false)))
  File.binwrite(revision.disk_file(search_if_not_exists: false), content)
  true
end

project = Project.find_by!(identifier: PROJECT_IDENTIFIER)
author = User.find_by(login: "aspice.author") || User.active.where(admin: true).first
User.current = author
root = ensure_folder(project, nil, ROOT_FOLDER, "Automotive SPICE 4.0 project work products and assessment evidence.", author)
folders = FOLDERS.to_h { |title, description| [title, ensure_folder(project, root, title, description, author)] }

MILESTONES.each do |name|
  version = Version.find_or_initialize_by(project: project, name: "ASPICE - #{name}")
  version.status = "open" if version.new_record?
  version.description = "Automotive SPICE 4.0 project milestone."
  version.save!
end

created = DOCUMENTS.count { |document| ensure_document(project, folders.fetch(document[0]), author, document) }
puts "ROOT=#{root.title}"
puts "FOLDERS=#{folders.size + 1}"
puts "DOCUMENTS=#{DOCUMENTS.size}"
puts "CREATED=#{created}"
puts "MILESTONES=#{MILESTONES.size}"

# frozen_string_literal: true

module AspiceDashboard
  class Snapshot
    REQUIREMENT_PROJECT = "aspice-requirements"
    VERIFICATION_PROJECT = "aspice-verification"
    REQUIREMENT_TRACKERS = [
      ["CReq", "Customer Requirement", "#2563eb"],
      ["SYS", "System Requirement", "#0f766e"],
      ["SWR", "Software Requirement", "#c2410c"],
      ["SWU", "Software Unit", "#7c3aed"]
    ].freeze
    TEST_TRACKERS = [
      ["SYS.4", "SYS.4 Verification"],
      ["SYS.5", "SYS.5 Verification"],
      ["SWE.4", "SWE.4 Verification"],
      ["SWE.5", "SWE.5 Verification"],
      ["SWE.6", "SWE.6 Verification"]
    ].freeze
    RESULT_COLORS = {
      "Pass" => "#16a34a",
      "Fail" => "#dc2626",
      "Blocked" => "#d97706",
      "Not Executed" => "#64748b"
    }.freeze

    attr_reader :product_counts, :result_counts, :paths

    def initialize
      @golden_path_field = IssueCustomField.find_by(name: "Golden Path")
      @verification_result_field = IssueCustomField.find_by(name: "Verification Result")
      @requirement_issues = project_issues(REQUIREMENT_PROJECT, REQUIREMENT_TRACKERS.map { |item| item[1] })
      @test_issues = project_issues(VERIFICATION_PROJECT, TEST_TRACKERS.map { |item| item[1] })
      @product_counts = build_product_counts
      @result_counts = build_result_counts
      @paths = build_paths
    end

    def total_products
      product_counts.values.sum
    end

    def total_tests
      @test_issues.size
    end

    def covered_paths
      paths.count { |path| path[:covered] }
    end

    def coverage_percent
      return 0 if paths.empty?

      (covered_paths * 100.0 / paths.size).round
    end

    def product_gradient
      gradient(product_counts.values, REQUIREMENT_TRACKERS.map { |item| item[2] } + ["#475569"])
    end

    def result_gradient
      gradient(RESULT_COLORS.keys.map { |result| result_counts[result] }, RESULT_COLORS.values)
    end

    def result_for(issue)
      field_value(issue, @verification_result_field).presence || "Not Executed"
    end

    private

    def project_issues(identifier, tracker_names)
      Issue.joins(:project, :tracker)
           .where(projects: { identifier: identifier }, trackers: { name: tracker_names })
           .includes(:tracker, :custom_values)
           .order(:id)
           .to_a
    end

    def build_product_counts
      counts = REQUIREMENT_TRACKERS.to_h do |label, tracker_name, _color|
        [label, @requirement_issues.count { |issue| issue.tracker.name == tracker_name }]
      end
      counts["Test Case"] = @test_issues.size
      counts
    end

    def build_result_counts
      RESULT_COLORS.keys.to_h do |result|
        [result, @test_issues.count { |issue| field_value(issue, @verification_result_field) == result }]
      end
    end

    def build_paths
      names = (@requirement_issues + @test_issues)
              .map { |issue| field_value(issue, @golden_path_field) }
              .compact_blank.uniq.sort
      names.map do |name|
        match = name.match(/\A(GP-\d+)\s*(.*)\z/)
        requirements = @requirement_issues.select { |issue| field_value(issue, @golden_path_field) == name }
        tests = @test_issues.select { |issue| field_value(issue, @golden_path_field) == name }
        test_by_tracker = tests.index_by { |issue| issue.tracker.name }
        required_requirement_trackers = REQUIREMENT_TRACKERS.map { |item| item[1] }
        {
          name: name,
          code: match ? match[1] : name,
          label: match ? match[2] : "",
          tests: TEST_TRACKERS.to_h { |label, tracker| [label, test_by_tracker[tracker]] },
          covered: required_requirement_trackers.all? { |tracker| requirements.any? { |issue| issue.tracker.name == tracker } } &&
                   TEST_TRACKERS.all? { |_label, tracker| test_by_tracker[tracker].present? }
        }
      end
    end

    def field_value(issue, field)
      field && issue.custom_field_value(field)
    end

    def gradient(values, colors)
      total = values.sum
      return "#cbd5e1" if total.zero?

      cursor = 0.0
      stops = values.each_with_index.filter_map do |value, index|
        next if value.zero?

        start = cursor
        cursor += value * 100.0 / total
        "#{colors[index]} #{start.round(2)}% #{cursor.round(2)}%"
      end
      "conic-gradient(#{stops.join(',')})"
    end
  end
end

class TravisLogParser

  def initialize(log_text)
    @log_text = log_text
    @ruby_regexp = Regexp.new("Running (Ruby .*)")
    @rails_regexp = Regexp.new("Running (Rails .*)")
    @time_regexp = Regexp.new("^(Started at .+)")

    @start_regexp = Regexp.new("(ERROR|FAILED|SKIPPED)_TEST:START")
    @end_regexp = Regexp.new("(ERROR|FAILED|SKIPPED)_TEST:END")

    @report_regexp = Regexp.new("\\d+ tests, \\d+ passed, (\\d+) failures, (\\d+) errors, \\d+ skips, \\d+ assertions")
  end

  def tests
    issues_list = []
    issue = nil
    empty_line = 0
    report = 0
    extra_info = {}
    @log_text.split("\n").each do |line|
      line.strip!
      line.gsub!(/\e\[[0-9;]+[mK]/,"")
      next if line.empty?

      if m = @ruby_regexp.match(line)
        extra_info[:ruby] = m[1]
      end

      if m = @rails_regexp.match(line)
        extra_info[:rails] = m[1]
      end

      if m = @report_regexp.match(line)
        report += m[1].to_i
        report += m[2].to_i
        if issue
          issue.save!
          issues_list << issue
        end
      end

      if m = @time_regexp.match(line)
        extra_info[:start_time] = m[1]
      end

      if m = @start_regexp.match(line)
        issue = Issue.new
        issue.extra_info = extra_info
        next
      end

      if issue
        if m = @end_regexp.match(line)
          issue.save!
          issues_list << issue
          issue = nil
        else
          issue << line
        end
      end
    end
    [issues_list, report]
  end
end

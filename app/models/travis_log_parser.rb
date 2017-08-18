class TravisLogParser

  def initialize(log_text)
    @log_text = log_text
    @fail_regexp = Regexp.new("(FAIL)|( FAIL )")
    @error_regexp = Regexp.new("(ERROR)|( ERROR )")
    @ruby_regexp = Regexp.new("Running (Ruby .*)")
    @rails_regexp = Regexp.new("Running (Rails .*)")
    @report_regexp = Regexp.new("\\d+ tests, \\d+ passed, (\\d+) failures, (\\d+) errors, \\d+ skips, \\d+ assertions")
    @time_regexp = Regexp.new("^(Started at .+)")
    @deprecated_regexp = Regexp.new("^DEPRECATION WARNING")
    @dotted_regexp = Regexp.new("^\\.+")
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

      if line.empty?
        next
      end
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

      #test/integration/applicants_old_checks_test.rb:307:
      if m = (@fail_regexp.match(line) or @error_regexp.match(line))
        issue = Issue.new
        issue.extra_info = extra_info
        empty_line = 0
      end
      if issue
        # puts line.inspect
        # if (line.empty? and empty_line > 1) or @dotted_regexp.match(line)
        if @dotted_regexp.match(line)
          issue.save!
          # puts "\e[33m" + "save" + "\e[39m"
          issues_list << issue
          issue = nil
        # elsif line.empty?
        #   empty_line+=1
        elsif @deprecated_regexp.match(line)
          # skip
        else
          issue << line
          # empty_line = 0
        end
        # puts "\e[32m" + "empty_line=#{(empty_line).inspect}" + "\e[39m"
      end
    end
    [issues_list, report]
  end
end

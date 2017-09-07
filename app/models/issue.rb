class Issue < ApplicationRecord
  after_initialize :init_vars
  before_save :parse_lines

  scope :for, -> (jira_username) {
    where(jira_username: jira_username)
  }

  validates_presence_of :jira_username

  def <<(line)
    @lines << line.gsub(/\e\[[0-9]+m/,"").strip
  end

  def reparse!
    self.title = nil
    parse_lines
    save!
  end

  def extra_info=(info)
    @lines << info[:start_time].presence
    @lines << info[:ruby].presence
    @lines << info[:rails].presence
    @lines.compact!
    @lines << ""
  end

  def description
    self.trace
  end

  protected
  def init_vars
    @test_regexp = Regexp.new("^(test/.*.rb):(\\d+):")
    @lines = []
  end

  def parse_lines
    self.trace = @lines.join("\n") if @lines.present?
    self.trace.split("\n").each do |line|
      if m = @test_regexp.match(line) #test/integration/applicants_old_checks_test.rb:307:
        # puts "\e[32m" + "m[1]=#{(m[1]).inspect}" + "\e[39m"
        self.title ||= "#{m[1]}:#{"%04d" % [m[2]]}"
      end
    end
  end
end

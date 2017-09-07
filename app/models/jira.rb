require 'json'

class Jira
  def initialize(username, password)
    options = {
      :username     => username,
      :password     => password,
      :site         => base_url,
      :context_path => '',
      :auth_type    => :basic
    }
    @jira_client = JIRA::Client.new(options)
  end

  def myself
    @jira_client.User.myself
  end

  def connected?
    begin
      myself
    rescue JIRA::HTTPError
      return false
    end
    true
  end

  def issues
    @_issues ||= jira_issues_cache
  end

  def create_issue(issue)
    new_issue = @jira_client.Issue.build
    saved = new_issue.save(
      'fields' => issue_fields_defaults.merge(
        {
          'summary' => issue.title,
          'description' => issue.description
        }
      )
    )
    if saved
      clear_jira_issues_cache
    else
      Rails.logger.info("create_issue(#{issue.id}")
      Rails.logger.info(new_issue.inspect)
      Rails.logger.info(new_issue.to_yaml)
    end
    new_issue
  end

  def reopen_and_comment_on_issue(issue_key, issue)
    jira_issue = issues.detect { |i| i.key == issue_key}
    if jira_issue.status.name == "Resolved"
      reopen_issue(jira_issue)
    end
    comment_on_issue(jira_issue, issue)
  end

  def reopen_issue(jira_issue)
    issue_transition = jira_issue.transitions.build
    saved = issue_transition.save!('transition' => { "id" => reopen_transition_id })
    if not saved
      Rails.logger.info("reopen_issue(#{jira_issue.key})")
      Rails.logger.info(jira_issue.inspect)
      Rails.logger.info(jira_issue.to_yaml)
    end
  end

  def comment_on_issue(jira_issue, issue)
    comment = jira_issue.comments.build
    saved = comment.save('body' => issue.trace)
    if not saved
      Rails.logger.info("comment_on_issue(#{issue_key}, #{issue.id}")
      Rails.logger.info(comment.inspect)
      Rails.logger.info(comment.to_yaml)
    end
  end

  def issue_url(jira_issue)
    "#{base_url}/browse/#{jira_issue[:key]}"
  end

  protected
  def jira_issues_cache_key
    "jira_issues"
  end

  def jira_issues_cache
    Rails.cache.fetch(jira_issues_cache_key, expires_in: 5.minutes) do
      search_jql = ENV["JIRA_SEARCH_JQL"] || raise("ENV['JIRA_SEARCH_JQL'] is undefined!")
      @jira_client.Issue.jql(search_jql)
    end
  end

  def clear_jira_issues_cache
    Rails.cache.delete(jira_issues_cache_key)
  end

  private
  def base_url
    ENV['JIRA_BASE_URL'] || raise("ENV['JIRA_BASE_URL'] is undefined!")
  end

  def issue_fields_defaults
    JSON.parse(ENV['JIRA_ISSUE_FIELDS_DEFAULT'] || '{}')
  end

  def reopen_transition_id
    ENV['JIRA_REOPEN_TRANSITION_ID'] || raise("ENV['JIRA_REOPEN_TRANSITION_ID'] is undefined!")
  end
end

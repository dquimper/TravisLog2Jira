module ApplicationHelper
  def issue_radio_button(form, jira_issue, levenshtein_distance)
    action = (jira_issue[:status] == "Resolved" ? "Reopen" : "Update")
    status = (jira_issue[:status] == "Resolved" ? jira_issue[:resolution] : jira_issue[:status])

    output = []
    output << label_tag do
      label_output = []
      label_output << form.radio_button(:action, "#{jira_issue[:key]}")
      label_output << "#{action} '#{jira_issue[:key]}: #{jira_issue[:summary]}' [#{[status, jira_issue[:assignee]].compact.join(" / ")}]"
      label_output.join(" ").html_safe
    end
    output << link_to("Open #{jira_issue[:key]}", @jira.issue_url(jira_issue), target: :blank)
    output << "(%.1f%% match)" % (100*(jira_issue[:summary].size.to_f-levenshtein_distance)/jira_issue[:summary].size.to_f)
    output.join(" ").html_safe
  end

  def help(help_tag)
    if session[help_tag].blank?
      yield
      session[help_tag] = Time.now
    end
  end
end

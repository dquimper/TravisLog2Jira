class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :verify_jira_session
  helper_method :jira_username

  protected
  def jira_username
    session[:jira_username]
  end

  def jira_password
    session[:jira_password]
  end

  def verify_jira_session
    if jira_username.blank? and jira_password.blank?
      redirect_to new_jira_session_path
    else
      @jira = Jira.new(jira_username, jira_password)
      if not @jira.connected?
        session[:jira_username] = nil
        session[:jira_password] = nil
        redirect_to new_jira_session_path, alert: "Login failed"
      end
    end
  end
end

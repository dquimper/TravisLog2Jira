class JiraSessionsController < ApplicationController
  skip_before_action :verify_jira_session

  # GET /jira_sessions/new
  def new
  end

  # POST /jira_sessions
  # POST /jira_sessions.json
  def create
    session[:jira_username] = params[:jira_session][:username]
    session[:jira_password] = params[:jira_session][:password]
    if session[:build_number].present?
      build_number = session[:build_number]
      session[:build_id] = nil
      redirect_to builds_path(id: build_number)
    else
      redirect_to root_path, notice: "Logged in!"
    end
  end

  # DELETE /jira_sessions/1
  # DELETE /jira_sessions/1.json
  def destroy
    session[:jira_username] = nil
    session[:jira_password] = nil
    redirect_to root_path, notice: "Logged out!"
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def jira_session_params
      params.require(:jira_session).permit(:username, :password)
    end
end

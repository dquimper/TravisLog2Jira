require "travis_log_parser"
require 'open-uri'


class IssuesController < ApplicationController
  before_action :verify_jira_session
  helper_method :matching_jira_issues

  def index
    @issues = Issue.for(jira_username).order(created_at: :desc)
  end

  def new
  end

  def create
    log_text = nil
    if build_number = params[:travis_log][:build_number].presence
      redirect_to builds_path(id: build_number)
    else
      if url = params[:travis_log][:url].presence
        open(url) do |f|
          log_text = f.read
        end
      end
      if params[:travis_log][:text].presence
        log_text = params[:travis_log][:text]
      end
      if log_text.present?
        tests, report = TravisLogParser.new(log_text, jira_username).tests
        if tests.size == report
          flash[:notice] = "#{tests.size} new issues found."
        else
          flash[:alert] = "#{tests.size} new issues found, but #{report-tests.size} couldn't be parsed."
        end
      else
        flash[:alert] = "No log to parse!"
      end

      redirect_to issues_path
    end
  end

  def edit
    @issue = Issue.find(params[:id])
  end

  def update
    @issue = Issue.find(params[:id])
    if @issue.update_attributes(issue_params)
      flash[:notice] = "Issue saved"
      redirect_to root_path
    else
      flash[:alert] = "An error occured! Try again."
      render :edit
    end
  end

  def execute
    @issue = Issue.find(params[:id])
    case issue_params[:action]
      when "new"
        @jira.create_issue(@issue)
      when "destroy"
        # Destroying @issue below
      else
        @jira.reopen_and_comment_on_issue(issue_params[:action], @issue)
    end

    @issue.destroy
    respond_to do |format|
      format.js
      format.json { render json: "OK", status: :success }
    end
  end

  protected
  def jira_issues
    @_jira_issues = []
    if @_jira_issues.empty?
      @jira.issues.each do |i|
        @_jira_issues << {
          key: i.key,
          summary: i.summary,
          status: i.status.name,
          resolution: i.resolution.try(:[], "name"),
          assignee: i.assignee.try(:displayName)
        }
      end
    end
    @_jira_issues
  end

  def matching_jira_issues(issue)
    threshold = 10
    distances = {}
    jira_issues.each do |i|
      distances[i] = [
        Vladlev.distance(issue.title, i[:summary], threshold),
        Vladlev.distance("Build failure: #{issue.title}", i[:summary], threshold),
        Vladlev.distance("#{File.basename(issue.title, File.extname(issue.title))}", i[:summary], threshold)
      ].min
    end
    distances.select { |i,d| d < threshold }.sort_by(&:last)
  end

  def issue_params
    params.require(:issue).permit(:title, :trace, :action)
  end


  # user     system      total        real

    # https://github.com/GlobalNamesArchitecture/damerau-levenshtein
    # DamerauLevenshtein.distance(i.title, j[:summary])
    # DamerauLevenshtein:    0.100000   0.010000   0.110000 (  0.106576)

    # https://github.com/dbalatero/levenshtein-ffi
    # Levenshtein.distance(i.title, j[:summary])
    # Levenshtein:          12.050000   0.120000  12.170000 ( 12.274638)

    # https://github.com/tliff/levenshtein
    # Levenshtein.distance(i.title, j[:summary])
    # levenshtein-ffi:       0.080000   0.000000   0.080000 (  0.076309)

    # https://github.com/mxenabled/vladlev
    # Vladlev.distance(i.title, j[:summary])
    # Vladlev:               0.070000   0.000000   0.070000 (  0.071638)
end

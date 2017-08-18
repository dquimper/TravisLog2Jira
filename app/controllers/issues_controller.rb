require "travis_log_parser"
require 'open-uri'


class IssuesController < ApplicationController
  before_action :verify_jira_session
  helper_method :matching_jira_issues

  def index
    @issues = Issue.all.order(created_at: :desc)

    @issues.each do |i|
      jira_issues.each do |j|
        Vladlev.distance(i.title, j[:summary])
      end
    end
  end

  def new
  end

  def create
    log_text = nil
    if url = params[:travis_log][:url].presence
      open(url) do |f|
        log_text = f.read
      end
    end
    if params[:travis_log][:text].presence
      log_text = params[:travis_log][:text]
    end
    if log_text.present?
      tests, report = TravisLogParser.new(log_text).tests
      if tests.size == report
        flash[:notice] = "#{tests.size} new issues parsed."
      else
        flash[:alert] = "#{tests.size} new issues parsed, but #{report-tests.size} couldn't be parsed."
      end
    else
      flash[:alert] = "No log to parse!"
    end

    redirect_to issues_path
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
        @jira.comment_on_issue(issue_params[:action], @issue)
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
          status: i.resolution.try(:[], "name") || i.status.name,
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
        Vladlev.distance("Build failure: #{issue.title}", i[:summary], threshold)
      ].min
    end
    distances.sort_by(&:last).select { |i,d| d < threshold }
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

class BuildsController < ApplicationController
  prepend_before_action :record_build_number

  def analyze
    build_number = params[:id]

    Travis::Pro.github_auth(github_token)
    repo = Travis::Pro::Repository.find(github_repo)
    build = repo.build(build_number)

    repo.session.clear_cache

    found_tests = 0
    reported_tests = 0
    if build.failed?
      build.jobs.each do |job|
        if job.failed?
          log_text = job.log.clean_body
          if log_text.present?
            tests, report = TravisLogParser.new(log_text, jira_username).tests
            found_tests += tests.size
            reported_tests += report
          end
        end
      end

      if found_tests == reported_tests
        flash[:notice] = "#{found_tests} new issues parsed."
      else
        flash[:alert] = "#{found_tests} new issues parsed, but #{reported_tests-found_tests} couldn't be parsed."
      end
    else
      flash[:notice] = "This build is successful!"
    end

    redirect_to issues_path
  end

  protected
  def github_token
    ENV["GITHUB_TOKEN"] || raise("ENV['GITHUB_TOKEN'] is undefined!")
  end

  def github_repo
    ENV["GITHUB_REPO"] || raise("ENV['GITHUB_REPO'] is undefined!")
  end

  def record_build_number
    session[:build_number] = params[:id]
  end
end

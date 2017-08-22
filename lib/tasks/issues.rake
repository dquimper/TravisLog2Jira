namespace :issues do
  desc "Reparse all issues"
  task :reparse => [:environment] do
    Issue.all.each do |issue|
      issue.reparse!
    end
  end
end

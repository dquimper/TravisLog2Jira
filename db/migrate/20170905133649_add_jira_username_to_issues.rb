class AddJiraUsernameToIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :issues, :jira_username, :string
    add_index :issues, :jira_username
  end
end

class AddGithubLoginToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :github_login, :string
  end
end

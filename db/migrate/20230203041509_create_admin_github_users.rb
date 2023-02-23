class CreateAdminGitHubUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :admin_github_users do |t|
      t.string :login
      t.string :avatar_url
      t.string :github_id
      t.json :info_data
      t.string :oauth_token
      t.boolean :is_admin

      t.timestamps
    end
    add_index :admin_github_users, :github_id, unique: true
  end
end

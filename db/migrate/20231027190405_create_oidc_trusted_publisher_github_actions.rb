class CreateOIDCTrustedPublisherGitHubActions < ActiveRecord::Migration[7.0]
  def change
    create_table :oidc_trusted_publisher_github_actions do |t|
      t.string :repository_owner, null: false
      t.string :repository_name, null: false
      t.string :repository_owner_id, null: false
      t.string :workflow_filename, null: false
      t.string :environment, null: true

      t.timestamps
    end

    add_index :oidc_trusted_publisher_github_actions,
      %i[repository_owner repository_name repository_owner_id workflow_filename environment],
      unique: true, name: "index_oidc_trusted_publisher_github_actions_claims"
  end
end

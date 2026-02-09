class AddWorkflowRepositoryToUniqueIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  OLD_COLUMNS = %i[repository_owner repository_name repository_owner_id workflow_filename environment].freeze
  NEW_COLUMNS = %i[repository_owner repository_name repository_owner_id workflow_filename environment
                   workflow_repository_owner workflow_repository_name].freeze

  def up
    remove_index :oidc_trusted_publisher_github_actions,
      OLD_COLUMNS,
      name: "index_oidc_trusted_publisher_github_actions_claims",
      algorithm: :concurrently

    add_index :oidc_trusted_publisher_github_actions,
      NEW_COLUMNS,
      name: "index_oidc_trusted_publisher_github_actions_claims",
      unique: true,
      algorithm: :concurrently
  end

  def down
    remove_index :oidc_trusted_publisher_github_actions,
      NEW_COLUMNS,
      name: "index_oidc_trusted_publisher_github_actions_claims",
      algorithm: :concurrently

    add_index :oidc_trusted_publisher_github_actions,
      OLD_COLUMNS,
      name: "index_oidc_trusted_publisher_github_actions_claims",
      unique: true,
      algorithm: :concurrently
  end
end

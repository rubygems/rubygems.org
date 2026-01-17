class CreateOIDCTrustedPublisherGitLab < ActiveRecord::Migration[8.0]
  def up
    drop_table :oidc_trusted_publisher_gitlabs, if_exists: true

    create_table :oidc_trusted_publisher_gitlabs do |t|
      t.string :project_path, null: false
      t.string :ci_config_path, null: false
      t.string :environment
      t.string :ref_type
      t.string :branch_name

      t.timestamps
    end

    add_index :oidc_trusted_publisher_gitlabs,
      %i[project_path ci_config_path environment ref_type branch_name],
      unique: true,
      name: "index_oidc_trusted_publisher_gitlabs_on_claims"
  end

  def down
    drop_table :oidc_trusted_publisher_gitlabs
  end
end

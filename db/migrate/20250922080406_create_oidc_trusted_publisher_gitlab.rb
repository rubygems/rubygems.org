class CreateOIDCTrustedPublisherGitLab < ActiveRecord::Migration[8.0]
  def change
    create_table :oidc_trusted_publisher_gitlabs do |t|
      t.string :project_path
      t.string :ref_path
      t.string :environment
      t.string :ci_config_ref_uri

      t.timestamps
    end
  end
end

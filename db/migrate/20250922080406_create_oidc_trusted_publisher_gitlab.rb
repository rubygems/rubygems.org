class CreateOIDCTrustedPublisherGitLab < ActiveRecord::Migration[8.0]
  def change
    create_table :oidc_trusted_publisher_gitlabs do |t|
      t.string :namespace_path
      t.string :project_path

      t.timestamps
    end
  end
end

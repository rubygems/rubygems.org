class AddWorkflowRepositoryToOIDCTrustedPublisherGitHubActions < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      change_table :oidc_trusted_publisher_github_actions, bulk: true do |t|
        t.string :workflow_repository_owner
        t.string :workflow_repository_name
      end
    end
  end
end

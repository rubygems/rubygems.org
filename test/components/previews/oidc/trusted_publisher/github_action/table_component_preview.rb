class OIDC::TrustedPublisher::GitHubAction::TableComponentPreview < Lookbook::Preview
  # @param environment text The environment for the GitHub Action
  # @param workflow_repository_owner text The owner of the repository containing the reusable workflow
  # @param workflow_repository_name text The name of the repository containing the reusable workflow
  def default(environment: nil, repository_name: nil, workflow_filename: nil,
    workflow_repository_owner: nil, workflow_repository_name: nil)
    github_action = FactoryBot.build(:oidc_trusted_publisher_github_action,
      **{ environment:, repository_name:, workflow_filename:,
          workflow_repository_owner:, workflow_repository_name: }.compact)
    render OIDC::TrustedPublisher::GitHubAction::TableComponent.new(github_action:)
  end
end

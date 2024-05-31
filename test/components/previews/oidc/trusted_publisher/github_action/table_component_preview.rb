class OIDC::TrustedPublisher::GitHubAction::TableComponentPreview < Lookbook::Preview
  # @param environment text The environment for the GitHub Action
  def default(environment: nil, repository_name: nil, workflow_filename: nil)
    github_action = FactoryBot.build(:oidc_trusted_publisher_github_action, **{ environment:, repository_name:, workflow_filename: }.compact)
    render OIDC::TrustedPublisher::GitHubAction::TableComponent.new(github_action:)
  end
end

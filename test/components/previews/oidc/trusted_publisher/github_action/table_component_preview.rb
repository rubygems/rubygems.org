class OIDC::TrustedPublisher::GitHubAction::TableComponentPreview < Lookbook::Preview
  # @param environment text The environment for the GitHub Action
  def default(environment: nil, repository_name: "rubygem2", workflow_filename: "push_gem.yml")
    github_action = FactoryBot.build(:oidc_trusted_publisher_github_action, environment:, repository_name:, workflow_filename:)
    render OIDC::TrustedPublisher::GitHubAction::TableComponent.new(github_action:)
  end
end

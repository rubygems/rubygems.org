# frozen_string_literal: true

class OIDC::TrustedPublisher::GitLab::TableComponentPreview < Lookbook::Preview
  # @param environment text The environment for the GitLab CI/CD job
  # @param project_path text The path to the GitLab project
  # @param ci_config_path text The path to the CI configuration file
  def default(environment: nil, project_path: nil, ci_config_path: nil)
    gitlab = FactoryBot.build(:oidc_trusted_publisher_gitlab,
      **{ environment:, project_path:, ci_config_path: }.compact)
    render OIDC::TrustedPublisher::GitLab::TableComponent.new(gitlab:)
  end
end

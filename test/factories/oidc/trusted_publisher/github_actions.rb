FactoryBot.define do
  factory :oidc_trusted_publisher_github_action, class: "OIDC::TrustedPublisher::GitHubAction" do
    repository_owner { "example" }
    sequence(:repository_name) { |n| "rubygem#{n}" }
    repository_owner_id { "123456" }
    workflow_filename { "push_gem.yml" }
    environment { nil }
  end
end

FactoryBot.define do
  factory :oidc_trusted_publisher_gitlab, class: "OIDC::TrustedPublisher::GitLab" do
    sequence(:project_path) { |n| "rubygem#{n}" }
    ref_path { "refs/heads/main" }
  end
end

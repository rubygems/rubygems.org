FactoryBot.define do
  factory :oidc_trusted_publisher_gitlab, class: "OIDC::TrustedPublisher::GitLab" do
    namespace_path { "example" }
    sequence(:project_path) { |n| "rubygem#{n}" }
  end
end

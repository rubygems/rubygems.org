FactoryBot.define do
  factory :oidc_trusted_publisher_gitlab, class: "OIDC::TrustedPublisher::GitLab" do
    sequence(:project_path) { |n| "group/rubygem#{n}" }
    ci_config_path { ".gitlab-ci.yml" }
  end
end

FactoryBot.define do
  factory :oidc_pending_trusted_publisher, class: "OIDC::PendingTrustedPublisher" do
    sequence(:rubygem_name) { |n| "pending-rubygem#{n}" }
    user
    association :trusted_publisher, factory: :oidc_trusted_publisher_github_action
    expires_at { 7.days.from_now }
  end
end

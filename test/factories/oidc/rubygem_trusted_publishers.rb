FactoryBot.define do
  factory :oidc_rubygem_trusted_publisher, class: "OIDC::RubygemTrustedPublisher" do
    rubygem
    trusted_publisher factory: %i[oidc_trusted_publisher_github_action]
  end
end

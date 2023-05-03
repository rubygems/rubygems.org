FactoryBot.define do
  factory :admin_github_user, class: "Admin::GitHubUser" do
    login { "jackson-keeling" }
    avatar_url { "MyString" }
    sequence(:github_id, &:to_s)

    oauth_token { SecureRandom.hex(10) }
    is_admin { false }
    info_data { { viewer: { login: login, id: github_id } } }

    trait :is_admin do
      is_admin { true }
      info_data do
        {
          viewer: {
            login: login,
            id: github_id,
            organization: {
              name: "RubyGems",
              login: "rubygems",
              viewerIsAMember: true,
              teams: {
                edges: [
                  { node: { slug: "rubygems-org" } },
                  { node: { slug: "security" } }
                ]
              }
            }
          }
        }
      end
    end
  end
end

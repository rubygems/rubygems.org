require "test_helper"

class OAuthTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
                                                                  provider: "github",
      uid: "95144751",
      info: {
        nickname: "jackson-keeling",
        email: "jackson.keeling@example.com",
        name: "Jackson Keeling",
        image: "https://via.placeholder.com/300x300.png",
        urls: {
          GitHub: "https://github.com/jackson-keeling"
        }
      },
      credentials: {
        token: "9ea49b946a31b705a0168295a0caa195",
        expires: false
      },
      extra: {
        raw_info: {
          login: "jackson-keeling",
          id: "95144751",
          avatar_url: "https://via.placeholder.com/300x300.png",
          gravatar_id: "",
          url: "https://api.github.com/users/jackson-keeling",
          html_url: "https://github.com/jackson-keeling",
          followers_url: "https://api.github.com/users/jackson-keeling/followers",
          following_url: "https://api.github.com/users/jackson-keeling/following{/other_user}",
          gists_url: "https://api.github.com/users/jackson-keeling/gists{/gist_id}",
          starred_url: "https://api.github.com/users/jackson-keeling/starred{/owner}{/repo}",
          subscriptions_url: "https://api.github.com/users/jackson-keeling/subscriptions",
          organizations_url: "https://api.github.com/users/jackson-keeling/orgs",
          repos_url: "https://api.github.com/users/jackson-keeling/repos",
          events_url: "https://api.github.com/users/jackson-keeling/events{/privacy}",
          received_events_url: "https://api.github.com/users/jackson-keeling/received_events",
          type: "User",
          site_admin: true,
          name: "Jackson Keeling",
          company: nil,
          blog: nil,
          location: "Paigeton, Massachusetts",
          email: "jackson.keeling@example.com",
          hireable: nil,
          bio: nil,
          public_repos: 263,
          public_gists: 658,
          followers: 294,
          following: 865,
          created_at: "2017-03-10T19:49:54+03:00",
          updated_at: "2017-04-04T10:32:08+03:00"
        }
      }
                                                                })
  end

  test "sets auth cookie when successful" do
    @octokit_stubs.get("/user/memberships/orgs/rubygems") { |_env| [200, { "Content-Type" => "application/json" }, JSON.generate(state: :active)] }
    @octokit_stubs.get("/orgs/rubygems/teams/rubygems-org/memberships/jackson-keeling") do |_env|
      [200, { "Content-Type" => "application/json" }, JSON.generate(state: :active)]
    end

    get admin_root_path(params: { a: :b })

    post html_document.at_css("form").attribute("action").value
    follow_redirect!

    assert_redirected_to admin_root_path(params: { a: :b })
    assert_not_nil cookies["rubygems_admin_oauth_github"]
    follow_redirect!

    assert_response :success
    assert page.has_selector? "h1", text: "RubyGems.org admin page"
    assert page.has_selector? "p", text: "You are currently logged in as jackson-keeling"
  end

  test "fails when user is not a member of the rubygems org" do
    @octokit_stubs.get("/user/memberships/orgs/rubygems") do |_env|
      [403, { "Content-Type" => "application/json" }, JSON.generate({ message: "bad" })]
    end

    get admin_root_path

    post html_document.at_css("form").attribute("action").value
    follow_redirect!

    assert_response :not_found
    assert_nil cookies["rubygems_admin_oauth_github"]
  end

  test "fails when user is not a member of the rubygems-org team" do
    @octokit_stubs.get("/user/memberships/orgs/rubygems") { |_env| [200, { "Content-Type" => "application/json" }, JSON.generate(state: :active)] }
    @octokit_stubs.get("/orgs/rubygems/teams/rubygems-org/memberships/jackson-keeling") do |_env|
      [400, { "Content-Type" => "application/json" }, JSON.generate(message: "bad")]
    end

    get admin_root_path

    post html_document.at_css("form").attribute("action").value
    follow_redirect!

    assert_response :not_found
    assert_nil cookies["rubygems_admin_oauth_github"]
  end
end

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

  def do_login
    get avo_path(params: { a: :b })
    post html_document.at_css("form").attribute("action").value
    follow_redirect!
  end

  test "sets auth cookie when successful" do
    info_data = {
      viewer: {
        login: "jackson-keeling",
        id: "95144751",
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
    stub_request(:post, "https://api.github.com/graphql")
      .with(body: { query: GitHubOAuthable::INFO_QUERY, variables: { organization_name: "rubygems" } }.to_json)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: JSON.generate(data: info_data)
      )

    do_login

    assert_redirected_to avo_path(params: { a: :b })
    assert_not_nil cookies["rubygems_admin_oauth_github_user"]
    follow_redirect!
    follow_redirect!

    assert_response :success
    assert page.assert_text "jackson-keeling"

    Admin::GitHubUser.admins.sole.tap do |user|
      assert user.is_admin
      assert_equal [{ slug: "rubygems-org" }, { slug: "security" }], user.teams
      assert user.team_member?("rubygems-org")
      refute user.team_member?("rubygems-org-not")
      assert_equal info_data, user.info_data
    end

    delete "/admin/logout"

    assert_redirected_to root_path
    assert_empty cookies["rubygems_admin_oauth_github_user"]
  end

  test "fails when user is not a member of the rubygems org" do
    info_data = {
      viewer: {
        login: "jackson-keeling",
        id: "95144751",
        organization: nil
      }
    }
    stub_request(:post, "https://api.github.com/graphql")
      .with(body: { query: GitHubOAuthable::INFO_QUERY, variables: { organization_name: "rubygems" } }.to_json)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: JSON.generate(data: info_data)
      )

    do_login

    assert_response :forbidden
    assert_nil cookies["rubygems_admin_oauth_github"]
    assert_equal "Validation failed: Is admin missing rubygems org, Is admin not a member of the rubygems org", response.body
    assert_empty Admin::GitHubUser.all
  end

  context "with an existing user for the github_id" do
    setup do
      @existing = FactoryBot.create(
        :admin_github_user,
        :is_admin
      )
    end

    should "login updates info data" do
      info_data = {
        viewer: {
          login: "#{@existing.login}_update",
          id: @existing.github_id,
          organization: {
            name: "RubyGems",
            login: "rubygems",
            viewerIsAMember: true,
            teams: {
              edges: [
                { node: { slug: "other-team" } },
                { node: { slug: "rubygems-org" } }
              ]
            }
          }
        }
      }
      stub_request(:post, "https://api.github.com/graphql")
        .with(body: { query: GitHubOAuthable::INFO_QUERY, variables: { organization_name: "rubygems" } }.to_json)
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: JSON.generate(data: info_data)
        )
      OmniAuth.config.mock_auth[:github].credentials.token += "_update"

      do_login

      assert_redirected_to avo_path(params: { a: :b })
      assert_not_nil cookies["rubygems_admin_oauth_github_user"]
      follow_redirect!
      follow_redirect!

      assert_response :success

      Admin::GitHubUser.admins.sole.tap do |user|
        assert user.is_admin
        assert user.login.ends_with?("_update")
        assert_equal @existing.github_id, user.github_id
        assert user.oauth_token.ends_with?("_update")
        assert_equal [{ slug: "other-team" }, { slug: "rubygems-org" }], user.teams
        assert_equal info_data, user.info_data
      end
    end

    should "login updates to non-admin" do
      info_data = {
        viewer: {
          login: @existing.login,
          id: @existing.github_id,
          organization: nil
        }
      }
      stub_request(:post, "https://api.github.com/graphql")
        .with(body: { query: GitHubOAuthable::INFO_QUERY, variables: { organization_name: "rubygems" } }.to_json)
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: JSON.generate(data: info_data)
        )

      do_login

      assert_nil cookies["rubygems_admin_oauth_github_user"]
      assert_response :forbidden

      Admin::GitHubUser.sole.tap do |user|
        refute user.is_admin
        assert_empty user.teams
        assert_equal info_data, user.info_data
      end
    end

    context "existing user is not an admin" do
      setup do
        @existing.update!(
          is_admin: false,
          info_data: {
            viewer: {
              login: @existing.login,
              id: @existing.github_id,
              organization: nil
            }
          }
        )
      end

      should "update to admin" do
        info_data = {
          viewer: {
            login: @existing.login,
            id: @existing.github_id,
            organization: {
              name: "RubyGems",
              login: "rubygems",
              viewerIsAMember: true,
              teams: {
                edges: [
                  { node: { slug: "rubygems-org" } }
                ]
              }
            }
          }
        }
        stub_request(:post, "https://api.github.com/graphql")
          .with(body: { query: GitHubOAuthable::INFO_QUERY, variables: { organization_name: "rubygems" } }.to_json)
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: JSON.generate(data: info_data)
          )

        do_login

        assert_redirected_to avo_path(params: { a: :b })
        assert_not_nil cookies["rubygems_admin_oauth_github_user"]
        follow_redirect!
        follow_redirect!

        assert_response :success

        Admin::GitHubUser.sole.tap do |user|
          assert user.is_admin
          assert_equal info_data, user.info_data
        end
      end

      should "stay non-admin" do
        info_data = {
          viewer: {
            login: @existing.login,
            id: @existing.github_id,
            organization: nil
          }
        }
        stub_request(:post, "https://api.github.com/graphql")
          .with(body: { query: GitHubOAuthable::INFO_QUERY, variables: { organization_name: "rubygems" } }.to_json)
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: JSON.generate(data: info_data)
          )

        do_login

        assert_nil cookies["rubygems_admin_oauth_github_user"]
        assert_response :forbidden

        Admin::GitHubUser.sole.tap do |user|
          refute user.is_admin
          assert_empty user.teams
          assert_equal info_data, user.info_data
        end
      end
    end
  end
end

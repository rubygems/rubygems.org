require "application_system_test_case"

class Avo::RubygemsSystemTest < ApplicationSystemTestCase
  def sign_in_as(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "1",
      credentials: {
        token: user.oauth_token,
        expires: false
      },
      info: {
        name: user.login
      }
    )
    @octokit_stubs.post("/graphql",
      {
        query: GitHubOAuthable::INFO_QUERY,
        variables: { organization_name: "rubygems" }
      }.to_json) do |_env|
      [200, { "Content-Type" => "application/json" }, JSON.generate(
        data: user.info_data
      )]
    end

    visit avo.root_path
    click_button "Log in with GitHub"

    page.assert_text user.login
  end

  test "release reserved namespace" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    rubygem = create(:rubygem)
    rubygem_attributes = rubygem.attributes.with_indifferent_access

    visit avo.resources_rubygem_path(rubygem)

    click_button "Actions"
    click_on "Release reserved namespace"

    assert_no_changes "Rubygem.find(#{rubygem.id}).attributes" do
      click_button "Release namespace"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"
    click_button "Release namespace"

    page.assert_text "Action ran successfully!"
    page.assert_text rubygem.to_global_id.uri.to_s

    rubygem.reload

    assert_equal 0, rubygem.protected_days

    audit = rubygem.audits.sole

    page.assert_text audit.id
    assert_equal "Rubygem", audit.auditable_type
    assert_equal "Release reserved namespace", audit.action
    assert_equal(
      {
        "records" => {
          "gid://gemcutter/Rubygem/#{rubygem.id}" => {
            "changes" => {
              "updated_at" => [rubygem_attributes[:updated_at].as_json, rubygem.updated_at.as_json]
            },
            "unchanged" => rubygem.attributes
              .except("updated_at")
              .transform_values(&:as_json)
          }
        },
        "fields" => {},
        "arguments" => {},
        "models" => ["gid://gemcutter/Rubygem/#{rubygem.id}"]
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment
  end
end

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

    stub_github_info_request(user.info_data)

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


  test "Yank a rubygem" do
    Minitest::Test.make_my_diffs_pretty!
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    security_user = create(:user, email: "security@rubygems.org")
    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem)

    visit avo.resources_rubygem_path(rubygem)

    click_button "Actions"
    click_on "Yank Rubygem"

    assert_no_changes "Rubygem.find(#{rubygem.id}).attributes" do
      click_button "Yank Rubygem"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"
    select(version.number, from: "Version")

    click_button "Yank Rubygem"

    page.assert_text "Action ran successfully!"
    page.assert_text rubygem.to_global_id.uri.to_s

    rubygem.reload
    version.reload

    assert_not_nil version.yanked_at
    assert_not_nil version.yanked_info_checksum

    audit = rubygem.audits.sole
    deletion = security_user.deletions.first

    page.assert_text audit.id
    assert_equal "Rubygem", audit.auditable_type
    assert_equal "Yank Rubygem", audit.action
    assert_equal(
      {
        "fields" => { "version" => version.id.to_s },
        "arguments" => {},
        "models" => ["gid://gemcutter/Rubygem/#{rubygem.id}"],
        "records" =>
        audit.audited_changes["records"].select do |k, _|
          k =~ %r{gid://gemcutter/Delayed::Backend::ActiveRecord::Job/\d+}
        end.merge(
          audit.audited_changes["records"].select do |k, _|
            k =~ %r{gid://gemcutter/Version/#{version.id}}
          end
        ).merge(
          audit.audited_changes["records"].select do |k, _|
            k =~ %r{gid://gemcutter/Deletion/#{deletion.id}}
          end
        ).merge(
          audit.audited_changes["records"].select do |k, _|
            k =~ %r{gid://gemcutter/Rubygem/#{rubygem.id}}
          end
        )
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment
  end

  test "Yank all version of rubygem" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    security_user = create(:user, email: "security@rubygems.org")
    rubygem = create(:rubygem)
    version1 = create(:version, rubygem: rubygem)
    version2 = create(:version, rubygem: rubygem)

    visit avo.resources_rubygem_path(rubygem)

    click_button "Actions"
    click_on "Yank Rubygem"

    assert_no_changes "Rubygem.find(#{rubygem.id}).attributes" do
      click_button "Yank Rubygem"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"
    select("All", from: "Version")

    click_button "Yank Rubygem"

    page.assert_text "Action ran successfully!"
    page.assert_text rubygem.to_global_id.uri.to_s

    rubygem.reload
    version1.reload
    version2.reload

    assert_not_nil version1.yanked_at
    assert_not_nil version1.yanked_info_checksum
    assert_not_nil version2.yanked_at
    assert_not_nil version2.yanked_info_checksum

    audit = rubygem.audits.sole
    deletion1 = security_user.deletions.first
    deletion2 = security_user.deletions.last

    page.assert_text audit.id
    assert_equal "Rubygem", audit.auditable_type
    assert_equal "Yank Rubygem", audit.action

    assert_equal(
      {
        "fields" => { "version" => "All" },
        "arguments" => {},
        "models" => ["gid://gemcutter/Rubygem/#{rubygem.id}"],
        "records" =>
        audit.audited_changes["records"].select do |k, _|
          k =~ %r{gid://gemcutter/Delayed::Backend::ActiveRecord::Job/\d+}
        end.merge(
          audit.audited_changes["records"].select do |k, _|
            k =~ %r{gid://gemcutter/Version/#{version1.id}}
          end
        ).merge(
          audit.audited_changes["records"].select do |k, _|
            k =~ %r{gid://gemcutter/Version/#{version2.id}}
          end
        ).merge(
          audit.audited_changes["records"].select do |k, _|
            k =~ %r{gid://gemcutter/Deletion/#{deletion1.id}}
          end
        ).merge(
          audit.audited_changes["records"].select do |k, _|
            k =~ %r{gid://gemcutter/Deletion/#{deletion2.id}}
          end
        ).merge(
          audit.audited_changes["records"].select do |k, _|
            k =~ %r{gid://gemcutter/Rubygem/#{rubygem.id}}
          end
        )
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment
  end
end

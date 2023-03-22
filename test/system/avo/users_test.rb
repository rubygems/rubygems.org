require "application_system_test_case"

class Avo::UsersSystemTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

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

  test "reset mfa" do
    Minitest::Test.make_my_diffs_pretty!
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    user = create(:user)
    user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
    user_attributes = user.attributes.with_indifferent_access

    visit avo.resources_user_path(user)

    click_button "Actions"
    click_on "Reset User 2FA"

    assert_no_changes "User.find(#{user.id}).attributes" do
      click_button "Reset MFA"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"
    click_button "Reset MFA"

    page.assert_text "Action ran successfully!"
    page.assert_text user.to_global_id.uri.to_s

    page.assert_no_text user.encrypted_password
    page.assert_no_text user_attributes[:encrypted_password]
    page.assert_no_text user_attributes[:mfa_seed]
    page.assert_no_text user_attributes[:mfa_recovery_codes].first

    user.reload

    assert_equal "disabled", user.mfa_level
    assert_not_equal user_attributes[:encrypted_password], user.encrypted_password
    assert_empty user.mfa_seed
    assert_empty user.mfa_recovery_codes

    audit = user.audits.sole

    page.assert_text audit.id
    assert_equal "User", audit.auditable_type
    assert_equal "Reset User 2FA", audit.action
    assert_equal(
      {
        "records" => {
          "gid://gemcutter/User/#{user.id}" => {
            "changes" => {
              "mfa_level" => %w[ui_and_api disabled],
              "updated_at" => [user_attributes[:updated_at].as_json, user.updated_at.as_json],
              "mfa_seed" => [user_attributes[:mfa_seed], ""],
              "mfa_recovery_codes" => [user_attributes[:mfa_recovery_codes], []],
              "encrypted_password" => [user_attributes[:encrypted_password], user.encrypted_password]
            },
            "unchanged" => user.attributes
              .except("mfa_level", "updated_at", "mfa_seed", "mfa_recovery_codes", "encrypted_password")
              .transform_values(&:as_json)
          }
        },
        "fields" => {},
        "arguments" => {},
        "models" => ["gid://gemcutter/User/#{user.id}"]
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment
  end

  test "block user" do
    Minitest::Test.make_my_diffs_pretty!
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    user = create(:user)
    user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
    user_attributes = user.attributes.with_indifferent_access

    visit avo.resources_user_path(user)

    click_button "Actions"
    click_on "Block User"

    assert_no_changes "User.find(#{user.id}).attributes" do
      click_button "Block User"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"
    click_button "Block User"

    page.assert_text "Action ran successfully!"
    page.assert_text user.to_global_id.uri.to_s

    page.assert_no_text user.encrypted_password
    page.assert_no_text user_attributes[:encrypted_password]
    page.assert_no_text user_attributes[:mfa_seed]
    page.assert_no_text user_attributes[:mfa_recovery_codes].first

    user.reload

    assert_equal "disabled", user.mfa_level
    assert_not_equal user_attributes[:encrypted_password], user.encrypted_password
    assert_empty user.mfa_seed
    assert_empty user.mfa_recovery_codes

    audit = user.audits.sole

    page.assert_text audit.id
    assert_equal "User", audit.auditable_type
    assert_equal "Block User", audit.action
    assert_equal(
      {
        "records" => {
          "gid://gemcutter/User/#{user.id}" => {
            "changes" => {
              "email" => [user_attributes[:email], user.email],
              "updated_at" => [user_attributes[:updated_at].as_json, user.updated_at.as_json],
              "confirmation_token" => [user_attributes[:confirmation_token], nil],
              "mfa_level" => %w[ui_and_api disabled],
              "mfa_seed" => [user_attributes[:mfa_seed], ""],
              "mfa_recovery_codes" => [user_attributes[:mfa_recovery_codes], []],
              "encrypted_password" => [user_attributes[:encrypted_password], user.encrypted_password],
              "api_key" => ["secret123", nil],
              "remember_token" => [user_attributes[:remember_token], nil],
              "blocked_email" => [nil, user_attributes[:email]]
            },
            "unchanged" => user.attributes
              .except(
                "api_key",
                "blocked_email",
                "confirmation_token",
                "email",
                "encrypted_password",
                "mfa_level",
                "mfa_recovery_codes",
                "mfa_seed",
                "remember_token",
                "updated_at"
              ).transform_values(&:as_json)
          }
        },
        "fields" => {},
        "arguments" => {},
        "models" => ["gid://gemcutter/User/#{user.id}"]
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment
  end

  test "reset api key" do
    perform_enqueued_jobs do
      admin_user = create(:admin_github_user, :is_admin)
      sign_in_as admin_user

      user = create(:user)
      user_attributes = user.attributes.with_indifferent_access

      visit avo.resources_user_path(user)

      click_button "Actions"
      click_on "Reset Api Key"

      assert_no_changes "User.find(#{user.id}).attributes" do
        click_button "Reset Api Key"
      end
      page.assert_text "Must supply a sufficiently detailed comment"

      fill_in "Comment", with: "A nice long comment"
      select("Public Gem", from: "Template")
      click_button "Reset Api Key"

      page.assert_text "Action ran successfully!"

      user.reload

      audit = user.audits.sole

      page.assert_text audit.id
      assert_equal "User", audit.auditable_type
      assert_equal "Reset Api Key", audit.action
      assert_equal(
        {
          "records" => {
            "gid://gemcutter/User/#{user.id}" => {
              "changes" => {
                "api_key" => ["secret123", user.api_key],
                "updated_at" => [user_attributes[:updated_at].as_json, user.updated_at.as_json]
              },
              "unchanged" => user.attributes
                .except(
                  "api_key",
                  "updated_at"
                ).transform_values(&:as_json)
            }
          },
          "fields" => { "template" => "public_gem_reset_api_key" },
          "arguments" => {},
          "models" => ["gid://gemcutter/User/#{user.id}"]
        },
        audit.audited_changes
      )
      assert_equal admin_user, audit.admin_github_user
      assert_equal "A nice long comment", audit.comment

      mailer = ActionMailer::Base.deliveries.find do |mail|
        mail.to.include?(user.email)
      end

      assert_equal("RubyGems.org API key was reset", mailer.subject)
    end

  test "Yank rubygems" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    user = create(:user)
    user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
    user_attributes = user.attributes.with_indifferent_access

    visit avo.resources_user_path(user)

    click_button "Actions"
    click_on "Yank all Rubygems"

    assert_no_changes "User.find(#{user.id}).attributes" do
      click_button "Yank all Rubygems"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"
    click_button "Yank all Rubygems"

    page.assert_text "Action ran successfully!"
    page.assert_text user.to_global_id.uri.to_s

    page.assert_no_text user.encrypted_password
    page.assert_no_text user_attributes[:encrypted_password]
    page.assert_no_text user_attributes[:mfa_seed]
    page.assert_no_text user_attributes[:mfa_recovery_codes].first

    user.reload

    audit = user.audits.sole

    page.assert_text audit.id
    assert_equal "User", audit.auditable_type
    assert_equal "Block User", audit.action
    assert_equal(
      {
        "records" => {
          "gid://gemcutter/User/#{user.id}" => {
            "changes" => {
              "email" => [user_attributes[:email], user.email],
              "updated_at" => [user_attributes[:updated_at].as_json, user.updated_at.as_json],
              "confirmation_token" => [user_attributes[:confirmation_token], nil],
              "mfa_level" => %w[ui_and_api disabled],
              "mfa_seed" => [user_attributes[:mfa_seed], ""],
              "mfa_recovery_codes" => [user_attributes[:mfa_recovery_codes], []],
              "encrypted_password" => [user_attributes[:encrypted_password], user.encrypted_password],
              "api_key" => ["secret123", nil],
              "remember_token" => [user_attributes[:remember_token], nil],
              "blocked_email" => [nil, user_attributes[:email]]
            },
            "unchanged" => user.attributes
              .except(
                "api_key",
                "blocked_email",
                "confirmation_token",
                "email",
                "encrypted_password",
                "mfa_level",
                "mfa_recovery_codes",
                "mfa_seed",
                "remember_token",
                "updated_at"
              ).transform_values(&:as_json)
          }
        },
        "fields" => {},
        "arguments" => {},
        "models" => ["gid://gemcutter/User/#{user.id}"]
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment
  end
end

require "application_system_test_case"

class Avo::UsersSystemTest < ApplicationSystemTestCase
  make_my_diffs_pretty!

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
    @ip_address = create(:ip_address, ip_address: "127.0.0.1")
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
    user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
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
    page.assert_no_text user_attributes[:totp_seed]
    page.assert_no_text user_attributes[:mfa_hashed_recovery_codes].first

    user.reload

    assert_equal "disabled", user.mfa_level
    assert_not_equal user_attributes[:encrypted_password], user.encrypted_password
    assert_nil user.totp_seed
    assert_empty user.mfa_hashed_recovery_codes

    audit = user.audits.sole
    event = user.events.where(tag: Events::UserEvent::PASSWORD_CHANGED).sole

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
              "totp_seed" => [user_attributes[:totp_seed], nil],
              "mfa_hashed_recovery_codes" => [user_attributes[:mfa_hashed_recovery_codes], []],
              "encrypted_password" => [user_attributes[:encrypted_password], user.encrypted_password]
            },
            "unchanged" => user.attributes
              .except("mfa_level", "updated_at", "totp_seed", "mfa_hashed_recovery_codes", "encrypted_password")
              .transform_values(&:as_json)
          },
          event.to_gid.as_json => {
            "changes" => event.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
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
    user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
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
    page.assert_no_text user_attributes[:totp_seed]
    page.assert_no_text user_attributes[:mfa_hashed_recovery_codes].first

    user.reload

    assert_equal "disabled", user.mfa_level
    assert_not_equal user_attributes[:encrypted_password], user.encrypted_password
    assert_nil user.totp_seed
    assert_empty user.mfa_hashed_recovery_codes

    audit = user.audits.sole
    email_added_event = user.events.where(tag: Events::UserEvent::EMAIL_ADDED).sole
    email_verified_event = user.events.where(tag: Events::UserEvent::EMAIL_VERIFIED).sole
    password_changed_event = user.events.where(tag: Events::UserEvent::PASSWORD_CHANGED).sole

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
              "totp_seed" => [user_attributes[:totp_seed], nil],
              "mfa_hashed_recovery_codes" => [user_attributes[:mfa_hashed_recovery_codes], []],
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
                "mfa_hashed_recovery_codes",
                "totp_seed",
                "remember_token",
                "updated_at"
              ).transform_values(&:as_json)
          },
          email_added_event.to_gid.as_json => {
            "changes" => email_added_event.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
          },
          email_verified_event.to_gid.as_json => {
            "changes" => email_verified_event.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
          },
          password_changed_event.to_gid.as_json => {
            "changes" => password_changed_event.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
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
      event = user.events.where(tag: Events::UserEvent::EMAIL_SENT).sole

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
            },
            event.to_gid.as_json => {
              "changes" => event.attributes.transform_values { [nil, _1.as_json] },
              "unchanged" => {}
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
  end

  test "Yank rubygems" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user
    security_user = create(:user, email: "security@rubygems.org")

    ownership = create(:ownership)
    user = ownership.user
    rubygem = ownership.rubygem
    version = create(:version, rubygem: rubygem)
    GemDownload.increment(
      100_001,
      rubygem_id: rubygem.id,
      version_id: version.id
    )

    user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
    version_attributes = version.attributes.with_indifferent_access

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

    rubygem.reload
    version.reload

    audit = user.audits.sole
    deletion = security_user.deletions.first
    version_yanked_event = rubygem.events.where(tag: Events::RubygemEvent::VERSION_YANKED).sole

    page.assert_text audit.id
    assert_equal "User", audit.auditable_type
    assert_equal "Yank all Rubygems", audit.action

    rubygem_audit = audit.audited_changes["records"].select do |k, _|
      k =~ %r{gid://gemcutter/Rubygem/#{rubygem.id}}
    end
    rubygem_updated_at_changes = rubygem_audit["gid://gemcutter/Rubygem/#{rubygem.id}"]["changes"]["updated_at"]

    assert_equal(
      {
        "records" => {
          "gid://gemcutter/Deletion/#{deletion.id}" => {
            "changes" => deletion.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
          },
          "gid://gemcutter/Version/#{version.id}" => {
            "changes" => {
              "indexed" => [true, false],
              "yanked_at" => [nil, version.yanked_at.as_json],
              "updated_at" => [version_attributes[:updated_at].as_json, version.updated_at.as_json],
              "yanked_info_checksum" => [nil, version.yanked_info_checksum]
            },
            "unchanged" => version.attributes.merge("latest" => true)
              .except(
                "indexed",
                "updated_at",
                "yanked_at",
                "yanked_info_checksum"
              ).transform_values(&:as_json)
          },
          "gid://gemcutter/Rubygem/#{rubygem.id}" => {
            "changes" => {
              "updated_at" => rubygem_updated_at_changes,
              "indexed" => [true, false]
            },
            "unchanged" => rubygem.attributes
              .except(
                "updated_at",
                "indexed"
              ).transform_values(&:as_json)
          },
          version_yanked_event.to_gid.to_s => {
            "changes" => version_yanked_event.attributes.transform_values { [nil, _1] }.as_json,
            "unchanged" => {}
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

  test "yank user" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user
    security_user = create(:user, email: "security@rubygems.org")

    user = create(:user)
    user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
    user_attributes = user.attributes.with_indifferent_access

    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem)
    create(:ownership, user: user, rubygem: rubygem)
    version_attributes = version.attributes.with_indifferent_access

    visit avo.resources_user_path(user)

    click_button "Actions"
    click_on "Yank User"

    assert_no_changes "User.find(#{user.id}).attributes" do
      click_button "Yank User"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"
    click_button "Yank User"

    page.assert_text "Action ran successfully!"
    page.assert_text user.to_global_id.uri.to_s

    page.assert_no_text user.encrypted_password
    page.assert_no_text user_attributes[:encrypted_password]
    page.assert_no_text user_attributes[:totp_seed]
    page.assert_no_text user_attributes[:mfa_hashed_recovery_codes].first

    user.reload
    rubygem.reload
    version.reload

    audit = user.audits.sole
    deletion = security_user.deletions.first

    page.assert_text audit.id
    assert_equal "User", audit.auditable_type
    assert_equal "Yank User", audit.action

    rubygem_audit = audit.audited_changes["records"].select do |k, _|
      k =~ %r{gid://gemcutter/Rubygem/#{rubygem.id}}
    end
    rubygem_updated_at_changes = rubygem_audit["gid://gemcutter/Rubygem/#{rubygem.id}"]["changes"]["updated_at"]
    email_added_event = user.events.where(tag: Events::UserEvent::EMAIL_ADDED).sole
    email_verified_event = user.events.where(tag: Events::UserEvent::EMAIL_VERIFIED).sole
    password_changed_event = user.events.where(tag: Events::UserEvent::PASSWORD_CHANGED).sole
    version_yanked_event = rubygem.events.where(tag: Events::RubygemEvent::VERSION_YANKED).sole

    assert_equal(
      {
        "records" => {
          "gid://gemcutter/Deletion/#{deletion.id}" => {
            "changes" => deletion.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
          },
          "gid://gemcutter/Version/#{version.id}" => {
            "changes" => {
              "indexed" => [true, false],
              "yanked_at" => [nil, version.yanked_at.as_json],
              "updated_at" => [version_attributes[:updated_at].as_json, version.updated_at.as_json],
              "yanked_info_checksum" => [nil, version.yanked_info_checksum]
            },
            "unchanged" => version.attributes.merge("latest" => true)
              .except(
                "indexed",
                "updated_at",
                "yanked_at",
                "yanked_info_checksum"
              ).transform_values(&:as_json)
          },
          "gid://gemcutter/Rubygem/#{rubygem.id}" => {
            "changes" => {
              "updated_at" => rubygem_updated_at_changes,
              "indexed" => [true, false]
            },
            "unchanged" => rubygem.attributes
              .except(
                "updated_at",
                "indexed"
              ).transform_values(&:as_json)
          },
          "gid://gemcutter/User/#{user.id}" => {
            "changes" => {
              "email" => [user_attributes[:email], user.email],
              "updated_at" => [user_attributes[:updated_at].as_json, user.updated_at.as_json],
              "confirmation_token" => [user_attributes[:confirmation_token], nil],
              "mfa_level" => %w[ui_and_api disabled],
              "totp_seed" => [user_attributes[:totp_seed], nil],
              "mfa_hashed_recovery_codes" => [user_attributes[:mfa_hashed_recovery_codes], []],
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
                "mfa_hashed_recovery_codes",
                "totp_seed",
                "remember_token",
                "updated_at"
              ).transform_values(&:as_json)
          },
          email_added_event.to_gid.as_json => {
            "changes" => email_added_event.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
          },
          email_verified_event.to_gid.as_json => {
            "changes" => email_verified_event.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
          },
          password_changed_event.to_gid.as_json => {
            "changes" => password_changed_event.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
          },
          version_yanked_event.to_gid.as_json => {
            "changes" => version_yanked_event.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
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

  test "change user email" do
    perform_enqueued_jobs do
      admin_user = create(:admin_github_user, :is_admin)
      sign_in_as admin_user

      user = create(:user)
      user_attributes = user.attributes.with_indifferent_access

      visit avo.resources_user_path(user)

      click_button "Actions"
      click_on "Change User Email"

      assert_no_changes "User.find(#{user.id}).attributes" do
        click_button "Change User Email"
      end
      page.assert_text "Must supply a sufficiently detailed comment"

      fill_in "Comment", with: "A nice long comment"
      fill_in "Email", with: "gem-maintainer-001@example.com"
      click_button "Change User Email"

      page.assert_text "Action ran successfully!"

      user.reload

      audit = user.audits.sole
      email_added_event = user.events.where(tag: Events::UserEvent::EMAIL_ADDED).sole
      email_sent_event = user.events.where(tag: Events::UserEvent::EMAIL_SENT).sole

      page.assert_text audit.id
      assert_equal "User", audit.auditable_type
      assert_equal "Change User Email", audit.action
      assert_equal(
        {
          "records" => {
            "gid://gemcutter/User/#{user.id}" => {
              "changes" => {
                "updated_at" => [user_attributes[:updated_at].as_json, user.updated_at.as_json],
                "email" => [user_attributes[:email], user.email],
                "email_confirmed" => [true, false],
                "confirmation_token" => [user_attributes[:confirmation_token], user.confirmation_token],
                "token_expires_at" => [user_attributes[:token_expires_at].as_json, user.token_expires_at.as_json]
              },
              "unchanged" => user.attributes
                .except(
                  "email",
                  "token_expires_at",
                  "email_confirmed",
                  "confirmation_token",
                  "updated_at"
                ).transform_values(&:as_json)
            },
            email_added_event.to_gid.as_json => {
              "changes" => email_added_event.attributes.transform_values { [nil, _1.as_json] },
              "unchanged" => {}
            },
            email_sent_event.to_gid.as_json => {
              "changes" => email_sent_event.attributes.transform_values { [nil, _1.as_json] },
              "unchanged" => {}
            }
          },
          "fields" => { "from_email" => "gem-maintainer-001@example.com" },
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

      assert_equal("Please confirm your email address with RubyGems.org", mailer.subject)
    end
  end

  test "create user" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    visit avo.resources_users_path

    click_button "Actions"
    click_on "Create User"

    assert_no_changes "User.count" do
      click_button "Create User"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"
    fill_in "Email", with: "gem-user-001@example.com"
    click_button "Create User"

    page.assert_text "Action ran successfully!"
    perform_enqueued_jobs

    user = User.sole
    audit = user.audits.sole
    event = user.events.where(tag: Events::UserEvent::CREATED).sole

    page.assert_text audit.id
    assert_equal "User", audit.auditable_type
    assert_equal "Create User", audit.action
    assert_equal(
      {
        "records" => {
          "gid://gemcutter/User/#{user.id}" => {
            "changes" =>   user.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
          },
          event.to_gid.as_json => {
            "changes" => event.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
          }
        },
        "fields" => { "email" => "gem-user-001@example.com" },
        "arguments" => {},
        "models" => nil
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment

    mailers = ActionMailer::Base.deliveries.select do |mail|
      mail.to.include?(user.email)
    end

    assert_equal(["Change your password"], mailers.map(&:subject))
  end
end

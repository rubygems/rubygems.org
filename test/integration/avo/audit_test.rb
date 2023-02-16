require "test_helper"

class Avo::AuditsTest < ActionDispatch::IntegrationTest
  include AdminHelpers
  include Capybara::Minitest::Assertions

  test "getting audits as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_audits_path
    assert_response :success

    audited_user = create(:user)
    version = create(:version)

    yanked_at = Time.utc(2022, 10, 10).to_datetime

    audit = create(:audit, auditable: audited_user, admin_github_user: create(:admin_github_user),
      comment: "This is a comment",
      audited_changes: {
        arguments: { "arg1" => "val1" },
        fields: { "field1" => "fieldval1" },
        models: [audited_user.to_global_id.uri, version.to_global_id.uri],
        records: {
          audited_user.to_global_id.uri => {
            "changes" => {
              "encrypted_password" => %w[encrypted_password_old encrypted_password_new]
            },
            "unchanged" => audited_user.attributes.except(:encrypted_password)
          },
          version.to_global_id.uri => {
            "changes" => {
              "indexed" => [true, false],
              "yanked_at" => [nil, yanked_at]
            },
            "unchanged" => version.attributes.except(:indexed, :yanked_at)
          }
        }
      })

    get avo.resources_audits_path
    assert_response :success

    get avo.resources_audit_path(audit)
    assert_response :success
    assert_text "This is a comment"

    assert_text audited_user.name
    assert_text "Encrypted password"
    refute_text "encrypted_password_old"
    refute_text "encrypted_password_new"
    refute_text audited_user.encrypted_password
    refute_text audited_user.api_key

    assert_text audited_user.name
    assert_text version.full_name
    assert_text "Indexed", count: 2
    assert_text "Yanked at", count: 2
  end
end

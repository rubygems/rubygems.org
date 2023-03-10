require "test_helper"

class Avo::AuditsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting audits as admin" do
    admin = create(:admin_github_user, :is_admin)
    admin_sign_in_as admin

    get avo.resources_audits_path

    assert_response :success

    user = create(:user)
    audit = create(:audit, auditable: user, models: [user], records: {
                     user.to_global_id.uri => {
                       "changes" => {
                         "encrypted_password" => %w[abc def]
                       },
                       "unchanged" => {}
                     }
                   })

    deleted_user = create(:user).tap(&:destroy!)
    deletion_audit = create(:audit, auditable: user, models: [deleted_user], records: {
                              deleted_user.to_global_id.uri => {
                                "changes" => {
                                  "id" => [deleted_user.id, nil],
                                  "encrypted_password" => ["abc", nil]
                                },
                                "unchanged" => {}
                              }
                            })

    insertion_audit = create(:audit, auditable: user, models: [deleted_user], records: {
                               user.to_global_id.uri => {
                                 "changes" => {
                                   "id" => [nil, user.id],
                                   "encrypted_password" => [nil, "abc"]
                                 },
                                 "unchanged" => {}
                               }
                             })

    empty_audit = create(:audit, auditable: user)

    get avo.resources_audits_path

    assert_response :success
    page.assert_text audit.action
    page.assert_text deletion_audit.action
    page.assert_text insertion_audit.action
    page.assert_text empty_audit.action

    get avo.resources_audit_path(audit)

    assert_response :success
    page.assert_text audit.action
    page.assert_text audit.comment

    get avo.resources_audit_path(deletion_audit)

    assert_response :success
    page.assert_text deletion_audit.action
    page.assert_text deletion_audit.comment

    get avo.resources_audit_path(insertion_audit)

    assert_response :success
    page.assert_text insertion_audit.action
    page.assert_text insertion_audit.comment

    get avo.resources_audit_path(empty_audit)

    assert_response :success
    page.assert_text empty_audit.action
    page.assert_text empty_audit.comment
  end
end

require "application_system_test_case"

class Avo::WebHooksSystemTest < ApplicationSystemTestCase
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

  test "delete webhook" do
    Minitest::Test.make_my_diffs_pretty!
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    web_hook = create(:global_web_hook)

    visit avo.resources_web_hook_path(web_hook)

    click_button "Actions"
    click_on "Delete Webhook"

    assert_no_changes "WebHook.find(#{web_hook.id}).attributes" do
      click_button "Delete Webhook"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"
    click_button "Delete Webhook"

    page.assert_text "Action ran successfully!"
    page.assert_text web_hook.to_global_id.uri.to_s

    audit = Audit.sole

    page.assert_text audit.id
    assert_equal "WebHook", audit.auditable_type
    assert_equal "Delete Webhook", audit.action
    assert_equal(
      {
        "records" => {
          "gid://gemcutter/WebHook/#{web_hook.id}" => {
            "changes" => {
              "id" => [web_hook.id, nil],
              "user_id" => [web_hook.user_id, nil],
              "url" => [web_hook.url, nil],
              "failure_count" => [0, nil],
              "created_at" => [web_hook.created_at.as_json, nil],
              "updated_at" => [web_hook.updated_at.as_json, nil],
              "successes_since_last_failure" => [0, nil],
              "failures_since_last_success" => [0, nil]
            },
            "unchanged" => {
              "rubygem_id" => nil,
              "disabled_reason" => nil,
              "disabled_at" => nil,
              "last_success" => nil,
              "last_failure" => nil
            }
          }
        }.merge(audit.audited_changes["records"].select { |k, _| k =~ %r{gid://gemcutter/Delayed::Backend::ActiveRecord::Job/\d+} }),
        "fields" => {},
        "arguments" => {},
        "models" => ["gid://gemcutter/WebHook/#{web_hook.id}"]
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

    assert_equal I18n.t("mailer.web_hook_deleted.subject"), last_email.subject
  end
end

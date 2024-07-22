require "application_system_test_case"

class Avo::ManualChangesSystemTest < ApplicationSystemTestCase
  make_my_diffs_pretty!

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

  test "auditing changes" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    Admin::LogTicketPolicy.any_instance.stubs(:avo_create?).returns(true)
    Admin::LogTicketPolicy.any_instance.stubs(:avo_update?).returns(true)
    Admin::LogTicketPolicy.any_instance.stubs(:avo_destroy?).returns(true)

    visit avo.resources_log_tickets_path
    click_on "Create new log ticket"

    fill_in "Key", with: "key"
    fill_in "Directory", with: "dir"
    fill_in "Processed count", with: "0"
    fill_in "Comment", with: "A nice long comment"
    click_on "Save"

    page.assert_text "key"
    page.assert_text "dir"
    page.assert_text "A nice long comment"
    page.assert_text "Manual create of LogTicket"

    log_ticket = LogTicket.sole

    page.assert_text log_ticket.id
    audit = Audit.sole

    page.assert_text audit.id
    assert_equal log_ticket, audit.auditable
    assert_equal "LogTicket", audit.auditable_type
    assert_equal "Manual create of LogTicket", audit.action
    assert_equal(
      {
        "records" => {
          "gid://gemcutter/LogTicket/#{log_ticket.id}" => {
            "changes" => log_ticket.attributes.transform_values { [nil, _1.as_json] },
            "unchanged" => {}
          }
        },
        "fields" => {
          "key" => "key",
          "directory" => "dir",
          "backend" => "s3",
          "status" => "pending",
          "processed_count" => "0"
        },
        "arguments" => {},
        "models" => ["gid://gemcutter/LogTicket/#{log_ticket.id}"]
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment

    find('div[data-field-id="auditable"]').click_on log_ticket.to_param

    page.assert_title(/^#{log_ticket.to_param}/)

    click_on "Edit"

    fill_in "Key", with: "Other Key"
    fill_in "Processed count", with: "2"
    select "failed", from: "Status"
    fill_in "Comment", with: "Another comment"
    click_on "Save"

    page.assert_text "Another comment"

    assert_equal 2, Audit.count

    audit = Audit.last

    page.assert_text audit.id
    assert_equal log_ticket, audit.auditable
    assert_equal "LogTicket", audit.auditable_type
    assert_equal "Manual update of LogTicket", audit.action
    assert_equal(
      {
        "records" => {
          "gid://gemcutter/LogTicket/#{log_ticket.id}" => {
            "changes" => {
              "key" => ["key", "Other Key"],
              "status" => %w[pending failed],
              "updated_at" => audit.audited_changes.dig("records", "gid://gemcutter/LogTicket/#{log_ticket.id}", "changes", "updated_at"),
              "processed_count" => [0, 2]
            },
            "unchanged" => log_ticket.reload.attributes.except("key", "status", "updated_at", "processed_count")
          }
        },
        "fields" => {
          "key" => "Other Key",
          "directory" => "dir",
          "backend" => "s3",
          "status" => "failed",
          "processed_count" => "2"
        },
        "arguments" => {},
        "models" => ["gid://gemcutter/LogTicket/#{log_ticket.id}"]
      }.as_json,
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "Another comment", audit.comment

    find('div[data-field-id="auditable"]').click_on log_ticket.to_param

    page.assert_title(/^#{log_ticket.to_param}/)

    accept_alert("Are you sure?") do
      click_on "Delete"
    end

    page.assert_text "Record destroyed"

    assert_raise(ActiveRecord::RecordNotFound) { log_ticket.reload }

    assert_equal 3, Audit.count
    audit = Audit.last
    visit avo.resources_audit_path(audit)

    page.assert_text "Manual destroy of LogTicket"

    assert_nil audit.auditable
    assert_equal log_ticket.id, audit.auditable_id
    assert_equal "LogTicket", audit.auditable_type
    assert_equal "Manual destroy of LogTicket", audit.action
    assert_equal(
      {
        "records" => {
          "gid://gemcutter/LogTicket/#{log_ticket.id}" => {
            "changes" => log_ticket.attributes.transform_values { [_1, nil] },
            "unchanged" => {}
          }
        },
        "fields" => {},
        "arguments" => {},
        "models" => ["gid://gemcutter/LogTicket/#{log_ticket.id}"]
      }.as_json,
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "Manual destroy of LogTicket", audit.comment
  end
end

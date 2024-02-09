require "application_system_test_case"

class Avo::RubygemsSystemTest < ApplicationSystemTestCase
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

    create(:ip_address, ip_address: "127.0.0.1")

    stub_github_info_request(user.info_data)

    visit avo.root_path
    click_button "Log in with GitHub"

    page.assert_text user.login
  end

  test "release reserved namespace" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    rubygem = create(:rubygem, created_at: 40.days.ago)
    rubygem_attributes = rubygem.attributes.with_indifferent_access

    refute_predicate rubygem, :pushable?

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
    assert_predicate rubygem, :pushable?

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
        ).merge(
          audit.audited_changes["records"].select do |k, _|
            k =~ %r{gid://gemcutter/Events::RubygemEvent/\d+}
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
        ).merge(
          audit.audited_changes["records"].select do |k, _|
            k =~ %r{gid://gemcutter/Events::RubygemEvent/\d+}
          end
        )
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment
  end

  test "add owner" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    security_user = create(:user, email: "security@rubygems.org")
    rubygem = create(:rubygem)
    create(:version, rubygem: rubygem)

    new_owner = create(:user)

    visit avo.resources_rubygem_path(rubygem)

    click_button "Actions"
    click_on "Add owner"

    assert_no_changes "Rubygem.find(#{rubygem.id}).then { [_1.attributes, _1.ownerships.map(&:attributes)]}" do
      click_button "Add owner"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"
    find_field("New owner").click
    send_keys new_owner.email
    find("li", text: new_owner.handle).click

    click_button "Add owner"

    page.assert_text "Added #{new_owner.handle} to #{rubygem.name}"
    page.assert_text rubygem.to_global_id.uri.to_s

    rubygem.reload

    ownership = rubygem.ownerships.where(user: new_owner).sole

    assert_predicate ownership, :confirmed?
    assert_equal security_user, ownership.authorizer

    audit = rubygem.audits.sole
    event = rubygem.events.where(tag: Events::RubygemEvent::OWNER_ADDED).sole

    page.assert_text audit.id
    assert_equal "Rubygem", audit.auditable_type
    assert_equal "Add owner", audit.action

    assert_equal(
      {
        "fields" => { "owner" => { "id" => new_owner.id, "handle" => new_owner.handle } },
        "arguments" => {},
        "models" => ["gid://gemcutter/Rubygem/#{rubygem.id}"],
        "records" =>
          {
            ownership.to_gid.to_s => {
              "changes" => {
                "id" => [nil, ownership.id],
                "rubygem_id" => [nil, rubygem.id],
                "user_id" => [nil, new_owner.id],
                "token" => [nil, ownership.token],
                "created_at" => [nil, ownership.created_at.as_json],
                "updated_at" => [nil, ownership.updated_at.as_json],
                "push_notifier" => [nil, true],
                "confirmed_at" => [nil, ownership.confirmed_at.as_json],
                "token_expires_at" => [nil, ownership.token_expires_at.as_json],
                "owner_notifier" => [nil, true],
                "authorizer_id" => [nil, security_user.id],
                "ownership_request_notifier" => [nil, true]
              },
              "unchanged" => {}
            },
            "gid://gemcutter/Events::RubygemEvent/#{event.id}" => {
              "changes" => event.attributes.transform_values { [nil, _1.as_json] },
              "unchanged" => {}
            }
          }
      },
      audit.audited_changes
    )
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment
  end

  test "upload versions file" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    visit avo.resources_rubygems_path

    _ = create(:version)

    click_button "Actions"
    click_on "Upload Versions File"
    fill_in "Comment", with: "A nice long comment"

    assert_enqueued_jobs 1, only: UploadVersionsFileJob do
      click_button "Upload"

      page.assert_text "Upload job scheduled"
    end

    assert_not_nil Audit.last
  end

  test "upload names file" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    visit avo.resources_rubygems_path

    _ = create(:version)

    click_button "Actions"
    click_on "Upload Names File"
    fill_in "Comment", with: "A nice long comment"

    assert_enqueued_jobs 1, only: UploadNamesFileJob do
      click_button "Upload"

      page.assert_text "Upload job scheduled"
    end

    assert_not_nil Audit.last
  end

  test "upload info file" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    version = create(:version)
    visit avo.resources_rubygem_path(version.rubygem)

    click_button "Actions"
    click_on "Upload Info File"
    fill_in "Comment", with: "A nice long comment"

    assert_enqueued_jobs 1, only: UploadInfoFileJob do
      click_button "Upload"

      page.assert_text "Upload job scheduled"
    end

    assert_not_nil Audit.last
  end
end

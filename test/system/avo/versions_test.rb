require "application_system_test_case"

class Avo::VersionsSystemTest < ApplicationSystemTestCase
  make_my_diffs_pretty!

  include ActiveJob::TestHelper

  test "restore a rubygem version" do
    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    rubygem = create(:rubygem)
    version = create(:version, rubygem: rubygem)
    deletion = create(:deletion, version: version)
    version_attributes = version.attributes.with_indifferent_access
    rubygem_attributes = rubygem.attributes.with_indifferent_access
    deletion_attributes = deletion.attributes.with_indifferent_access

    visit avo.resources_version_path(version)

    click_button "Actions"
    click_on "Restore version"

    assert_no_changes "Version.find(#{version.id}).attributes" do
      click_button "Restore version"
    end
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "A nice long comment"

    click_button "Restore version"

    page.assert_text "Action ran successfully!"
    page.assert_text version.to_global_id.uri.to_s

    rubygem.reload
    version.reload

    assert deletion.version.indexed
    assert_nil version.yanked_at
    assert_nil version.yanked_info_checksum

    audit = version.audits.sole

    page.assert_text audit.id
    assert_equal "Version", audit.auditable_type
    assert_equal "Restore version", audit.action
    assert_equal admin_user, audit.admin_github_user
    assert_equal "A nice long comment", audit.comment
    rubygem_audit = audit.audited_changes["records"].select do |k, _|
      k =~ %r{gid://gemcutter/Rubygem/#{rubygem.id}}
    end
    rubygem_updated_at_changes = rubygem_audit["gid://gemcutter/Rubygem/#{rubygem.id}"]["changes"]["updated_at"]
    version_unyank_event = rubygem.events.where(tag: Events::RubygemEvent::VERSION_UNYANKED).sole

    assert_equal(
      {
        "records" =>  {
          "gid://gemcutter/Version/#{version.id}" =>
          {
            "changes" =>
            {
              "indexed" => [false, true],
              "yanked_at" => [version_attributes[:yanked_at].as_json, nil],
              "yanked_info_checksum" => [version_attributes[:yanked_info_checksum], nil],
              "updated_at" => [version_attributes[:updated_at].as_json, version.updated_at.as_json]
            },
            "unchanged" => version_attributes
              .except("updated_at", "yanked_info_checksum", "yanked_at", "indexed")
              .merge("position" => 0, "latest" => false)
              .transform_values(&:as_json)
          },
          "gid://gemcutter/Rubygem/#{rubygem.id}" =>
          {
            "changes" =>
            {
              "updated_at" => rubygem_updated_at_changes,
              "indexed" => [false, true]
            },
            "unchanged" => rubygem_attributes
              .except("updated_at", "indexed")
              .transform_values(&:as_json)
          },
          "gid://gemcutter/Deletion/#{deletion.id}" =>
          {
            "changes" =>
            {
              "id" => [deletion.id, nil],
              "user_id" => [deletion_attributes[:user_id], nil],
              "rubygem" => [rubygem.name, nil],
              "number" => [version_attributes[:number], nil],
              "platform" => ["ruby", nil],
              "created_at" => [deletion.created_at.as_json, nil],
              "updated_at" => [deletion.updated_at.as_json, nil],
              "version_id" => [version.id, nil]
            },
            "unchanged" => {}
          },
          version_unyank_event.to_gid.to_s => {
            "changes" => version_unyank_event.attributes.transform_values { [nil, _1] }.as_json,
            "unchanged" => {}
          }
        },
        "fields" => {},
        "arguments" => {},
        "models" => ["gid://gemcutter/Version/#{version.id}"]
      },
      audit.audited_changes
    )

    assert_event Events::RubygemEvent::VERSION_UNYANKED, {
      number: version.number,
      platform: version.platform,
      version_gid: version.to_gid.to_s
    }, version_unyank_event
  end

  test "run afer version write job" do
    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    rubygem = create(:rubygem, owners: [create(:user)])
    version = create(:version, rubygem: rubygem)

    visit avo.resources_version_path(version)

    click_button "Actions"
    click_on "Run version post-write job"

    fill_in "Comment", with: "A nice long comment"

    click_button "Run Job"

    page.assert_text "Action ran successfully!"
    page.assert_text version.to_global_id.uri.to_s

    perform_enqueued_jobs

    assert_equal 1, ActionMailer::Base.deliveries.size

    rubygem.reload
    version.reload

    audit = version.audits.sole

    assert_equal(
      ["gid://gemcutter/Version/#{version.id}"],
      audit.audited_changes["models"]
    )
  end
end

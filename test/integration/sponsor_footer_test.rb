# frozen_string_literal: true

require "test_helper"

class SponsorFooterTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "rollout preserves existing logos and records control public footer and logo reads" do
    task = Maintenance::SeedFooterSponsorsTask.new
    task.collection.each { |entry| task.process(entry) }

    assert_equal ["Ruby Central", "AWS", "DNSimple", "Datadog", "Fastly", "Honeybadger", "Mend"], Sponsor.in_footer.pluck(:name)
    ruby_central = Sponsor.find_by!(name: "Ruby Central")
    ruby_central.update!(position: 20)
    task.collection.each { |entry| task.process(entry) }

    assert_equal 7, Sponsor.count
    assert_equal 20, ruby_central.reload.position

    get page_path("about")

    assert_select "footer use[href$='#ruby-central']"

    with_feature FeatureFlag::SPONSOR_FOOTER do
      Sponsor.find_by!(name: "AWS").update!(position: 30)
      Sponsor.find_by!(name: "Mend").update!(anonymous: true)
      Sponsor.find_by!(name: "DNSimple").update!(show_in_footer: false)
      get page_path("about")

      assert_response :success
      assert_select "footer a[aria-label]" do |links|
        names = links.map { |link| link["aria-label"] }.select { |name| Sponsor.exists?(name:) }

        assert_equal ["Datadog", "Fastly", "Honeybadger", "Ruby Central", "AWS"], names
      end
      refute_includes response.body, rails_blob_path(Sponsor.find_by!(name: "Mend").logo)
      refute_includes response.body, rails_blob_path(Sponsor.find_by!(name: "DNSimple").logo)

      logo_url = rails_blob_path(ruby_central.logo)
      get logo_url

      assert_response :success
      assert_equal "image/png", response.media_type
      assert_equal ruby_central.logo.download, response.body.b
      assert_includes response.headers["Cache-Control"], "no-store"
      ruby_central.update!(anonymous: true)
      get logo_url

      assert_response :not_found
      ruby_central.update!(anonymous: false, show_in_footer: false)
      get logo_url

      assert_response :not_found

      outsider = create(:admin_github_user, :is_admin)
      info_data = outsider.info_data.deep_dup
      info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
      outsider.update!(info_data:)
      admin_sign_in_as outsider
      get logo_url

      assert_response :not_found

      admin_sign_in_as create(:admin_github_user, :is_admin)
      get logo_url

      assert_response :success
    end
  end
end

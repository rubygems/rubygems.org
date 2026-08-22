# frozen_string_literal: true

require "test_helper"

class Card::TimelineComponentTest < ComponentTest
  should "render timeline item without link to user" do
    datetime = 1.2.days.ago

    render Card::TimelineComponent.new do |c|
      c.timeline_item(datetime) do
        "additional content"
      end
    end

    assert_selector "time[datetime='#{datetime.iso8601}']"
    assert_text "additional content"
  end

  should "render pusher link for a version pushed via GitHub Actions trusted publishing" do
    trusted_publisher = create(:oidc_trusted_publisher_github_action)
    version = create(:version, pusher: nil, pusher_api_key: create(:api_key, :trusted_publisher, owner: trusted_publisher))

    render Card::TimelineComponent.new do |c|
      c.timeline_item(version.authored_at, c.link_to_pusher(version)) do
        "pushed"
      end
    end

    assert_text "GitHub Actions"
    assert_selector "img[alt='GitHub'][title='#{trusted_publisher.name}']"
  end

  should "render pusher link for a version pushed via GitLab trusted publishing" do
    trusted_publisher = create(:oidc_trusted_publisher_gitlab)
    version = create(:version, pusher: nil, pusher_api_key: create(:api_key, :trusted_publisher, owner: trusted_publisher))

    render Card::TimelineComponent.new do |c|
      c.timeline_item(version.authored_at, c.link_to_pusher(version)) do
        "pushed"
      end
    end

    assert_text "GitLab CI"
    assert_selector "img[alt='GitLab'][title='#{trusted_publisher.name}']"
  end
end

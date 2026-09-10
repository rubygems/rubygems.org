# frozen_string_literal: true

require "test_helper"

class OrganizationPushNotificationsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include GemspecYamlTemplateHelpers

  setup do
    @pusher = create(:user, email: "pusher@rubygems-test.org")
    @member = create(:user, email: "member@rubygems-test.org")
    @rubygem = create(:rubygem, name: "org-gem", number: "1.0.0")
    @organization = create(:organization, owners: [@pusher], maintainers: [@member], rubygems: [@rubygem])
    @api_key = create(:api_key, owner: @pusher)
  end

  test "sends gem pushed email to confirmed organization members with push_notifier enabled" do
    push_version("2.0.0")

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)

    assert_includes recipients, @pusher.email
    assert_includes recipients, @member.email
  end

  test "does not send gem pushed email to organization members with push_notifier disabled" do
    @member.memberships.find_by!(organization: @organization).update!(push_notifier: false)

    push_version("2.0.0")

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)

    assert_includes recipients, @pusher.email
    assert_not_includes recipients, @member.email
  end

  test "does not send gem pushed email to unconfirmed organization members" do
    unconfirmed_member = create(:user, email: "pending@rubygems-test.org")
    create(:membership, :pending, user: unconfirmed_member, organization: @organization)

    push_version("2.0.0")

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)

    assert_not_includes recipients, unconfirmed_member.email
  end

  test "sends gem yanked email to confirmed organization members with push_notifier enabled" do
    push_version("2.0.0")
    version = @rubygem.versions.find_by!(number: "2.0.0")

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      Deletion.create!(version: version, user: @pusher)
    end

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)

    assert_includes recipients, @pusher.email
    assert_includes recipients, @member.email
  end

  test "does not send gem yanked email to organization members with push_notifier disabled" do
    @member.memberships.find_by!(organization: @organization).update!(push_notifier: false)

    push_version("2.0.0")
    version = @rubygem.versions.find_by!(number: "2.0.0")

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      Deletion.create!(version: version, user: @pusher)
    end

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)

    assert_includes recipients, @pusher.email
    assert_not_includes recipients, @member.email
  end

  private

  def push_version(number)
    gem = build_gem(new_gemspec("org-gem", number, "Gemcutter", "ruby"))
    Pusher.new(@api_key, gem).process
    gem.close
  end
end

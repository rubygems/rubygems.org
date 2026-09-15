# frozen_string_literal: true

require "test_helper"

class Maintenance::RevokeCacheExposedApiKeysTaskTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @task = Maintenance::RevokeCacheExposedApiKeysTask.new
  end

  context "#collection" do
    should "select unexpired legacy keys, skipping scoped and expired keys" do
      legacy = create(:api_key, :legacy_broad, key: "live-legacy")
      scoped = create(:api_key, name: "ci-key", key: "scoped")
      expired = create(:api_key, :legacy_broad, key: "dead-legacy")
      expired.expire!

      collection = @task.collection

      assert_includes collection, legacy
      refute_includes collection, scoped
      refute_includes collection, expired
    end
  end

  context "#collection canary bounds" do
    setup do
      @keys = create_list(:api_key, 3, :legacy_broad).sort_by(&:id)
    end

    should "apply min_api_key_id as an inclusive lower bound" do
      @task.min_api_key_id = @keys[1].id

      assert_equal @keys[1..], @task.collection.order(:id).to_a
    end

    should "apply max_api_key_id as an inclusive upper bound" do
      @task.max_api_key_id = @keys[1].id

      assert_equal @keys[0..1], @task.collection.order(:id).to_a
    end

    should "apply both bounds together" do
      @task.min_api_key_id = @keys[1].id
      @task.max_api_key_id = @keys[1].id

      assert_equal [@keys[1]], @task.collection.order(:id).to_a
    end

    should "be invalid when max_api_key_id is below min_api_key_id" do
      @task.min_api_key_id = 10
      @task.max_api_key_id = 5

      refute_predicate @task, :valid?
      assert_includes @task.errors[:max_api_key_id], "must be greater than or equal to min_api_key_id"
    end
  end

  context "#process" do
    should "expire an unexpired key and record the deletion event" do
      api_key = create(:api_key)

      assert_changes -> { api_key.owner.events.where(tag: Events::UserEvent::API_KEY_DELETED).count }, from: 0, to: 1 do
        @task.process(api_key)
      end

      assert_predicate api_key.reload, :expired?
    end

    should "record an incident-specific revocation event on the owner" do
      api_key = create(:api_key, :legacy_broad)
      events = api_key.owner.events.where(tag: Events::UserEvent::CACHE_EXPOSURE_KEY_REVOKED)

      assert_changes -> { events.count }, from: 0, to: 1 do
        @task.process(api_key)
      end
    end

    should "not send email (notification is a separate task)" do
      api_key = create(:api_key)

      assert_no_enqueued_emails do
        @task.process(api_key)
      end
    end

    should "be idempotent: a second run does not re-revoke or re-record" do
      api_key = create(:api_key)
      @task.process(api_key)

      assert_no_changes -> { api_key.owner.events.where(tag: Events::UserEvent::API_KEY_DELETED).count } do
        @task.process(api_key.reload)
      end
    end

    should "roll back the expiration and record no events when the incident-event write fails" do
      # The notify audience depends on the expiration and the incident marker committing
      # atomically. Let expire!'s real work happen (expires_at + API_KEY_DELETED), then make
      # ONLY the subsequent incident-event write raise, as a DB failure would. Non-incident
      # tags delegate to the real record_event!, so the API_KEY_DELETED insert genuinely runs
      # and the assertions below prove it is rolled back, not merely never attempted.
      api_key = create(:api_key, :legacy_broad)
      owner = api_key.owner
      original = owner.method(:record_event!)
      owner.define_singleton_method(:record_event!) do |tag, **kwargs|
        raise ActiveRecord::StatementInvalid, "simulated incident-event failure" if
          tag == Events::UserEvent::CACHE_EXPOSURE_KEY_REVOKED
        original.call(tag, **kwargs)
      end

      assert_raises(ActiveRecord::StatementInvalid) { @task.process(api_key) }

      assert_not api_key.reload.expired?, "expiration must roll back with the failed incident-event write"
      assert_equal 0, owner.events.where(tag: Events::UserEvent::API_KEY_DELETED).count,
        "expire!'s API_KEY_DELETED must not commit"
      assert_equal 0, owner.events.where(tag: Events::UserEvent::CACHE_EXPOSURE_KEY_REVOKED).count,
        "the incident marker must not commit"
    end
  end
end

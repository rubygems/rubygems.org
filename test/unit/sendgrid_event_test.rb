require "test_helper"

class SendgridEventTest < ActiveSupport::TestCase
  context ".fails_since_last_delivery" do
    should "return 0 for email with no events" do
      assert_equal 0, SendgridEvent.fails_since_last_delivery("user@example.com")
    end

    should "return 0 for email with no delivery failures" do
      create(:sendgrid_event, event_type: "delivered", occurred_at: 1.day.ago, email: "user@example.com")

      assert_equal 0, SendgridEvent.fails_since_last_delivery("user@example.com")
    end

    should "return number of mail delivery failures" do
      freeze_time do
        create(:sendgrid_event, event_type: "dropped", occurred_at: 1.day.ago, email: "user@example.com")
        create(:sendgrid_event, event_type: "bounce", occurred_at: 2.days.ago, email: "user@example.com")
        create(:sendgrid_event, event_type: "dropped", occurred_at: 3.days.ago, email: "user@example.com")
      end

      assert_equal 3, SendgridEvent.fails_since_last_delivery("user@example.com")
    end

    should "return number of delivery failures for given email only" do
      freeze_time do
        create(:sendgrid_event, email: "user.a@example.com", event_type: "bounce", occurred_at: 1.day.ago)
        create(:sendgrid_event, email: "user.b@example.com", event_type: "bounce", occurred_at: 2.days.ago)
        create(:sendgrid_event, email: "user.a@example.com", event_type: "bounce", occurred_at: 3.days.ago)
      end

      assert_equal 2, SendgridEvent.fails_since_last_delivery("user.a@example.com")
      assert_equal 1, SendgridEvent.fails_since_last_delivery("user.b@example.com")
    end

    should "count no more than one delivery failure per day" do
      freeze_time do
        create(:sendgrid_event, occurred_at: 1.day.ago, event_type: "dropped", email: "user@example.com")
        create(:sendgrid_event, occurred_at: 1.day.ago, event_type: "bounce", email: "user@example.com")
        create(:sendgrid_event, occurred_at: 2.days.ago, event_type: "bounce", email: "user@example.com")
        create(:sendgrid_event, occurred_at: 2.days.ago, event_type: "bounce", email: "user@example.com")
        create(:sendgrid_event, occurred_at: 2.days.ago, event_type: "dropped", email: "user@example.com")
      end

      assert_equal 2, SendgridEvent.fails_since_last_delivery("user@example.com")
    end

    should "only count failures since last successful delivery" do
      freeze_time do
        create(:sendgrid_event, event_type: "bounce", occurred_at: 1.day.ago, email: "user@example.com")
        create(:sendgrid_event, event_type: "delivered", occurred_at: 2.days.ago, email: "user@example.com")
        create(:sendgrid_event, event_type: "dropped", occurred_at: 3.days.ago, email: "user@example.com")
        create(:sendgrid_event, event_type: "bounce", occurred_at: 4.days.ago, email: "user@example.com")
        create(:sendgrid_event, event_type: "delivered", occurred_at: 5.days.ago, email: "user@example.com")
      end

      assert_equal 1, SendgridEvent.fails_since_last_delivery("user@example.com")
    end
  end

  context ".process_later" do
    should "create event" do
      occurred_at = 1.minute.ago.change(usec: 0)

      SendgridEvent.process_later(
        email: "user@example.com",
        sg_event_id: "t61hI0Xpmk8XSR1YX4s0Kg==",
        event: "bounce",
        timestamp: occurred_at.to_i
      )

      event = SendgridEvent.last
      assert_equal("user@example.com", event.email)
      assert_equal("t61hI0Xpmk8XSR1YX4s0Kg==", event.sendgrid_id)
      assert_equal("bounce", event.event_type)
      assert_equal(occurred_at, event.occurred_at)
      assert_predicate event, :pending?
      assert_equal(
        {
          "email" => "user@example.com",
          "sg_event_id" => "t61hI0Xpmk8XSR1YX4s0Kg==",
          "event" => "bounce",
          "timestamp" => occurred_at.to_i
        },
        event.payload
      )
    end

    should "schedule job to process event later" do
      SendgridEvent.process_later(
        email: "user@example.com",
        sg_event_id: "t61hI0Xpmk8XSR1YX4s0Kg==",
        timestamp: Time.current.to_i
      )

      assert_equal 1, Delayed::Job.count
    end

    should "gracefully ignore duplicate events" do
      2.times do
        SendgridEvent.process_later(
          sg_event_id: "t61hI0Xpmk8XSR1YX4s0Kg==",
          timestamp: Time.current.to_i
        )
      end

      assert_equal 1, SendgridEvent.count
    end
  end

  context ".process" do
    should "process event with given id" do
      event = create(:sendgrid_event, status: "pending")

      assert_changes -> { event.reload.status }, from: "pending", to: "processed" do
        SendgridEvent.process(event.id)
      end
    end
  end

  context "#process" do
    should "update user mail_fails" do
      user = create(:user)
      event = create(:sendgrid_event, email: user.email, event_type: "dropped", occurred_at: Time.current)

      assert_changes -> { user.reload.mail_fails }, from: 0, to: 1 do
        event.process
      end
    end

    should "mark event as processed" do
      event = create(:sendgrid_event, status: "pending")

      assert_changes -> { event.reload.status }, from: "pending", to: "processed" do
        event.process
      end
    end

    should "ignore processed events" do
      user = create(:user)
      event = create(
        :sendgrid_event, status: "processed", email: user.email, event_type: "dropped", occurred_at: Time.current
      )

      assert_no_changes -> { user.reload.mail_fails } do
        event.process
      end
    end
  end

  context "#pending?" do
    should "be true for pending event" do
      event = SendgridEvent.new(status: "pending")
      assert_predicate event, :pending?
    end

    should "be false for processed event" do
      event = SendgridEvent.new(status: "processed")
      refute_predicate event, :pending?
    end
  end
end

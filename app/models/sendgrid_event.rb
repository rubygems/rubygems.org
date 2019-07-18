# frozen_string_literal: true

class SendgridEvent < ApplicationRecord
  # To make allowances for occasional inbox down time, this counts a maximum of one fail per day,
  # e.g.:
  #
  # - If 2 emails are sent on the same day, and both fail, then this counts as only 1 fail, not
  #   2 fails.
  #
  # - If 2 emails are sent on 2 separate days, and both fail, then this counts as 2
  #   fails, as the failures were on different days.
  def self.fails_since_last_delivery(email)
    last_delivered_at = where(email: email, event_type: "delivered").maximum(:occurred_at)

    fails_query =
      select("DISTINCT(date_trunc('day', occurred_at))")
        .where(email: email, event_type: %w[dropped bounce])

    fails_query = fails_query.where("occurred_at > ?", last_delivered_at) if last_delivered_at

    fails_query.count
  end

  def self.process_later(payload)
    return if where(sendgrid_id: payload[:sg_event_id]).exists?

    transaction do
      event = create!(
        sendgrid_id: payload[:sg_event_id],
        email: payload[:email],
        event_type: payload[:event],
        occurred_at: Time.zone.at(payload[:timestamp]),
        payload: payload,
        status: "pending"
      )
      delay.process(event.id)
    end
  end

  def self.process(id)
    find(id).process
  end

  def process
    return unless pending?

    transaction do
      if email.present?
        fails_count = self.class.fails_since_last_delivery(email)
        User.where(email: email).update_all(mail_fails: fails_count)
      end
      update_attribute(:status, "processed")
    end
  end

  def pending?
    status == "pending"
  end
end

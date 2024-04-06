# frozen_string_literal: true

class SendgridEventsController < ApplicationController
  # Safelist documented SendGrid Event attributes
  # https://sendgrid.com/docs/API_Reference/Event_Webhook/event.html#-Event-objects
  SENDGRID_EVENT_ATTRIBUTES = %i[
    email timestamp smtp-id event category sg_event_id sg_message_id reason
    status response attempt useragent ip url asm_group_id tls unique_args
    marketing_campaign_id marketing_campaign_name pool type
  ].freeze

  skip_before_action :verify_authenticity_token, only: :create

  http_basic_authenticate_with(
    name: ENV.fetch("SENDGRID_WEBHOOK_USERNAME", "#{Rails.env}_sendgrid_webhook_user"),
    password: ENV.fetch("SENDGRID_WEBHOOK_PASSWORD", "password")
  )

  def create
    existing = SendgridEvent.where(sendgrid_id: events_params.pluck(:sg_event_id)).pluck(:sendgrid_id).to_set
    events_params.each do |event_payload|
      next unless existing.add?(event_payload.require(:sg_event_id))

      SendgridEvent.process_later(event_payload)
    end
    head :ok
  end

  private

  def events_params
    # SendGrid send a JSON array of 1+ events. Each event is a JSON object, see docs:
    # https://sendgrid.com/docs/for-developers/tracking-events/event/
    params_fetch(_json: SENDGRID_EVENT_ATTRIBUTES)
  end
end

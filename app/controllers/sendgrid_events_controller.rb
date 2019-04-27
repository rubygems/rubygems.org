# frozen_string_literal: true

class SendgridEventsController < ApplicationController
  # Safelist documented SendGrid Event attributes
  # https://sendgrid.com/docs/API_Reference/Event_Webhook/event.html#-Event-objects
  SENDGRID_EVENT_ATTRIBUTES = %w[
    email timestamp smtp-id event category sg_event_id sg_message_id reason
    status response attempt useragent ip url asm_group_id tls unique_args
    marketing_campaign_id marketing_campaign_name pool type
  ].freeze

  skip_before_action :verify_authenticity_token, only: :create

  http_basic_authenticate_with(
    name: Rails.application.secrets.sendgrid_webhook_username,
    password: Rails.application.secrets.sendgrid_webhook_password
  )

  def create
    events_params.each do |event_payload|
      SendgridEvent.process_later(event_payload)
    end
    head :ok
  end

  private

  def events_params
    # SendGrid send a JSON array of 1+ events. Each event is a JSON object, see docs:
    # https://sendgrid.com/docs/for-developers/tracking-events/event/
    params.require(:_json).map { |event_params| event_params.permit(SENDGRID_EVENT_ATTRIBUTES) }
  end
end

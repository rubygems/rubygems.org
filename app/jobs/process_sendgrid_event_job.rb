class ProcessSendgridEventJob < ApplicationJob
  queue_as :default

  def perform(sendgrid_event:)
    sendgrid_event.process
  end
end

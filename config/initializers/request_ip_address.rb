# frozen_string_literal: true

Rails.application.config.after_initialize do
  ActiveSupport.on_load(:action_dispatch_request) do
    include Gemcutter::RequestIpAddress
  end
end

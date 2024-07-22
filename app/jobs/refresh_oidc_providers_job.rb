class RefreshOIDCProvidersJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    OIDC::Provider.find_each do |provider|
      RefreshOIDCProviderJob.perform_later(provider:)
    end
  end
end

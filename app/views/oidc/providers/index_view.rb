# frozen_string_literal: true

class OIDC::Providers::IndexView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo

  attr_reader :providers_pagy, :providers

  def initialize(providers_pagy:, providers:)
    @providers_pagy = providers_pagy
    @providers = providers
    super()
  end

  def view_template
    self.title = t(".title")

    div(class: "t-body") do
      p do
        t(".description_html")
      end
      hr
      header(class: "gems__header push--s") do
        p(class: "gems__meter l-mb-0") { plain helpers.pagy_info(providers_pagy) }
      end
      ul do
        providers.each do |provider|
          li { link_to provider.issuer, profile_oidc_provider_path(provider) }
        end
      end
      plain helpers.pagy_nav(providers_pagy) if providers_pagy.pages > 1
    end
  end
end

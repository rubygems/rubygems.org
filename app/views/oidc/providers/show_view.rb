# frozen_string_literal: true

class OIDC::Providers::ShowView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo

  attr_reader :provider

  def initialize(provider:)
    @provider = provider
    super()
  end

  def template
    self.title = t(".title")

    div(class: "") do
      dl(class: "t-body provider_attributes") do
        supported_attrs.each do |attr|
          val = provider.configuration.send(attr)
          next if val.blank?
          dt { provider.configuration.class.human_attribute_name(attr) }
          dd do
            attr.end_with?("s_supported") ? tags_attr(attr, val) : text_attr(attr, val)
          end
        end
      end

      div(class: "t-body") do
        hr
        h3(class: "t-list__heading") { "Roles" }

        div(class: "") do
          api_key_roles = helpers.current_user.oidc_api_key_roles.where(provider:).page(0).per(10)
          header(class: "gems__header push--s") do
            p(class: "gems__meter l-mb-0") { plain helpers.page_entries_info(api_key_roles) }
          end
          render OIDC::ApiKeyRole::TableComponent.new(api_key_roles:) if api_key_roles.present?
        end
      end
    end
  end

  def supported_attrs
    (provider.configuration.required_attributes + provider.configuration.optional_attributes).map!(&:to_s)
  end

  def tags_attr(_attr, val)
    ul(class: "tag-list") do
      val.each do |t|
        li { code { t } }
      end
    end
  end

  def text_attr(attr, val)
    code do
      case attr
      when "issuer", /_(uri|endpoint)$/
        link_to(val, val)
      else
        val
      end
    end
  end
end

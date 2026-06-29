# frozen_string_literal: true

class OIDC::Providers::ShowView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ContentFor

  attr_reader :provider

  def initialize(provider:)
    @provider = provider
    super()
  end

  def view_template
    self.title = t(".title")

    subject_sidebar

    render CardComponent.new do |c|
      c.head { c.title(provider.issuer, icon: "settings") }

      dl do
        supported_attrs.each do |attr|
          val = provider.configuration.send(attr)
          next if val.blank?
          dt(class: "#{HEADING} mt-4") { provider.configuration.class.human_attribute_name(attr) }
          dd(class: "mt-1 mb-6") do
            attr.end_with?("s_supported") ? tags_attr(attr, val) : text_attr(attr, val)
          end
        end
      end

      h3(class: HEADING) { "Roles" }
      div(class: "mt-1") do
        api_key_roles = current_user.oidc_api_key_roles.where(provider:).page(0).per(10)
        header(class: "flex items-center py-4") do
          p(class: HEADING) { plain page_entries_info(api_key_roles) }
        end
        render OIDC::ApiKeyRole::TableComponent.new(api_key_roles:) if api_key_roles.present?
      end
    end
  end

  private

  HEADING = "text-sm text-neutral-600 dark:text-neutral-400 uppercase tracking-wide"
  LINK_CLASSES = "text-orange-500 hover:underline dark:text-orange-400"
  TAG_CLASSES = "rounded bg-neutral-100 dark:bg-neutral-900 px-2 py-1 text-c4"

  def subject_sidebar
    content_for :subject do
      view_context.render(partial: "dashboards/subject", locals: { user: current_user, current: :profile })
    end
  end

  def supported_attrs
    (provider.configuration.required_attributes + provider.configuration.optional_attributes).map!(&:to_s)
  end

  def tags_attr(_attr, val)
    ul(class: "flex flex-wrap gap-2") do
      val.each do |t|
        li { code(class: TAG_CLASSES) { t } }
      end
    end
  end

  def text_attr(attr, val)
    code do
      case attr
      when "issuer", /_(uri|endpoint)$/
        link_to(val, val, class: LINK_CLASSES)
      else
        val
      end
    end
  end
end

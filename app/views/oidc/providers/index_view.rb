# frozen_string_literal: true

class OIDC::Providers::IndexView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ContentFor

  attr_reader :providers

  def initialize(providers:)
    @providers = providers
    super()
  end

  def view_template
    self.title = t(".title")

    subject_sidebar

    render CardComponent.new do |c|
      c.head { c.title(t(".title"), icon: "settings") }

      p(class: "text-b2 mb-6") { t(".description_html") }

      header(class: "flex items-center py-4") do
        p(class: HEADING) { plain page_entries_info(providers) }
      end

      table(class: "w-full text-left border-separate") do
        thead do
          tr do
            th { OIDC::Provider.human_attribute_name(:issuer) }
          end
        end
        tbody do
          providers.each do |provider|
            tr(class: "text-sm") do
              td(data: { title: "Issuer" }) do
                link_to provider.issuer, profile_oidc_provider_path(provider), class: LINK_CLASSES
              end
            end
          end
        end
      end

      plain paginate(providers)
    end
  end

  private

  HEADING = "text-sm text-neutral-600 dark:text-neutral-400 uppercase tracking-wide"
  LINK_CLASSES = "text-orange-500 hover:underline dark:text-orange-400"

  def subject_sidebar
    content_for :subject do
      view_context.render(partial: "dashboards/subject", locals: { user: current_user, current: :profile })
    end
  end
end

# frozen_string_literal: true

module OIDC::RubygemTrustedPublishers::Concerns::Title
  extend ActiveSupport::Concern

  included do
    include Phlex::Rails::Helpers::ContentFor
  end

  private

  # Wraps the page body in the per-gem "subject" layout (matching the gem's
  # other sub-pages, e.g. security events): the gem sidebar on the left and a
  # heading that links back to the gem above the yielded content.
  def gem_subject_page(&)
    self.title = t(".title")

    if gem_versions?
      content_for(:subject) { raw(view_context.render("rubygems/aside")) } # rubocop:disable Rails/OutputSafety -- trusted Rails partial
      content_for(:subject_secondary) { raw(view_context.render("rubygems/aside_secondary")) } # rubocop:disable Rails/OutputSafety -- trusted Rails partial
    end

    div(class: "flex flex-col gap-8 pb-16 lg:pt-10 text-neutral-800 dark:text-neutral-200") do
      div do
        h1(class: "text-h4 font-semibold text-neutral-900 dark:text-white") { t(".title") }
        p(class: "text-b2 mt-2") do
          raw t(".subtitle_owner_html",
            gem_html: view_context.link_to(rubygem.name, rubygem_path(rubygem.slug), class: "text-orange-500 hover:text-orange-600"))
        end
      end

      yield
    end
  end

  # The gem sidebar partials require a latest version; gems without one render
  # without the sidebar, mirroring the gem's other subject pages.
  def gem_versions?
    view_context.instance_variable_get(:@latest_version).present?
  end
end

# frozen_string_literal: true

class Rubygems::SecurityEventsView < ApplicationView
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  extend Dry::Initializer

  option :rubygem
  option :security_events

  def template
    title_content

    div(class: "tw-space-y-2 t-body") do
      p do
        t(".description_html", gem: helpers.link_to(rubygem.name, rubygem_path(rubygem.slug)))
      end

      render Events::TableComponent.new(security_events: security_events)
    end
  end

  def title_content
    self.title_for_header_only = t(".title")
    content_for :title do
      h1(class: "t-display page__heading page__heading-small") do
        plain t(".title")
      end
    end
  end
end

# frozen_string_literal: true

class Profiles::SecurityEventsView < ApplicationView
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::DistanceOfTimeInWordsToNow
  include Phlex::Rails::Helpers::TimeTag
  include Phlex::Rails::Helpers::LinkTo
  extend Dry::Initializer

  option :security_events

  def view_template
    title_content

    div(class: "tw-space-y-2 t-body") do
      p do
        t(".description_html")
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

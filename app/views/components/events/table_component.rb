# frozen_string_literal: true

class Events::TableComponent < ApplicationComponent
  include Phlex::DeferredRender
  include Phlex::Rails::Helpers::DistanceOfTimeInWordsToNow
  include Phlex::Rails::Helpers::TimeTag
  include Phlex::Rails::Helpers::DOMClass

  extend Phlex::Rails::HelperMacros

  define_value_helper :current_user
  define_value_helper :page_entries_info
  define_value_helper :paginate

  extend Dry::Initializer

  option :security_events

  def template
    header(class: "gems__header push--s") do
      p(class: "gems__meter l-mb-0") { plain page_entries_info(security_events) }
    end

    if security_events.any?
      table(class: "owners__table") do
        thead do
          tr(class: "owners__row owners__header") do
            th(class: "owners__cell") { t(".event") }
            th(class: "owners__cell") { t(".time") }
            th(class: "owners__cell") { t(".additional_info") }
          end
        end

        tbody(class: "t-body") do
          security_events.each do |token|
            row(token)
          end
        end
      end
    end

    plain paginate(security_events)
  end

  private

  def tag_header(tag)
    key = "events.#{tag.source_type}_event.#{tag.subject_type}.#{tag.to_s.sub(/\A.+?:/, '').tr(':', '_')}"
    h4 { t(key, default: tag.to_s) }
  end

  def row(event)
    tr(class: "owners__row #{dom_class(event)}__#{event.tag}") do
      td(class: "owners__cell !tw-text-start") do
        event_details(event)
      end
      td(class: "owners__cell") do
        time_tag(event.created_at, distance_of_time_in_words_to_now(event.created_at))
        plain " ago"
      end
      td(class: "owners__cell !tw-text-start") do
        additional_info(event)
      end
    end
  end

  def event_details(event)
    tag_header event.tag
    component_name = "#{event.class.name}::#{event.tag.to_a.drop(1).map(&:classify).join('::')}Component".classify
    component = component_name.safe_constantize
    return if component.blank?
    render component.new(event:)
  end

  def additional_info(event)
    return unless event.tags.key?(event.tag)
    return if event.geoip_info.nil? && (event.additional.blank? && event.additional.user_agent_info.nil?)

    p(class: "!tw-mb-0") do
      break div { t(".redacted") } unless show_additional_info?(event)

      if event.geoip_info.present?
        div do
          plain event.geoip_info.to_s
        end
      end

      div do
        ua = event.additional.user_agent_info
        plain ua&.to_s || t(".no_user_agent_info")
      end
    end
  end

  def show_additional_info?(event)
    return true if event.has_attribute?(:user_id) && event.user == current_user
    return true if event.additional.has_attribute?("actor_gid") && event.additional.actor_gid == current_user.to_gid

    false
  end
end

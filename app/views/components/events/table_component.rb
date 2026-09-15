# frozen_string_literal: true

class Events::TableComponent < ApplicationComponent
  include Phlex::Rails::Helpers::DistanceOfTimeInWordsToNow
  include Phlex::Rails::Helpers::TimeTag
  include Phlex::Rails::Helpers::DOMClass

  extend Phlex::Rails::HelperMacros

  register_value_helper :current_user

  prop :security_events, reader: :public

  TH = "py-2 px-3 text-b4 font-semibold text-neutral-900 dark:text-white align-bottom"
  TD = "py-3 px-3 align-top text-b3 text-neutral-800 dark:text-neutral-200"
  MUTED = "text-b4 text-neutral-600 dark:text-neutral-400"

  def view_template
    header(class: "flex items-center mb-6") do
      p(class: "text-xs text-neutral-500 uppercase tracking-wide") { page_entries_info(security_events) }
    end

    if security_events.any?
      div(class: "overflow-x-auto") do
        table(class: "w-full text-left border-collapse") do
          thead do
            tr(class: "border-b-2 border-neutral-300 dark:border-neutral-700") do
              th(scope: "col", class: TH) { t(".event") }
              th(scope: "col", class: "#{TH} text-nowrap") { t(".time") }
              th(scope: "col", class: TH) { t(".additional_info") }
            end
          end

          tbody do
            security_events.each do |token|
              row(token)
            end
          end
        end
      end
    end

    paginate(security_events, theme: "hammy")
  end

  private

  def tag_header(tag)
    key = Events::Tag.translation_key(tag)
    h4(class: "text-b2 font-semibold text-neutral-900 dark:text-white mb-1") { t(key, default: tag.to_s) }
  end

  def row(event)
    tr(class: "#{dom_class(event)}__#{event.tag} odd:bg-neutral-100 dark:odd:bg-neutral-900") do
      td(class: TD) do
        event_details(event)
      end
      td(class: "#{TD} #{MUTED} text-nowrap") do
        time_tag(event.created_at, distance_of_time_in_words_to_now(event.created_at))
        plain " ago"
      end
      td(class: TD) do
        additional_info(event)
      end
    end
  end

  def event_details(event)
    tag_header event.tag
    component_name = "#{event.class.name}::#{Events::Tag.const_name(event.tag)}Component"
    component = component_name.safe_constantize
    return if component.blank?
    render component.new(event:)
  end

  def additional_info(event)
    return unless event.tags.key?(event.tag)
    return if event.geoip_info.nil? && event.additional.blank? && event.additional.user_agent_info.nil?

    div(class: MUTED) do
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
    return true if event.additional.has_attribute?("actor_gid") && event.additional.actor_gid == current_user&.to_gid

    false
  end
end

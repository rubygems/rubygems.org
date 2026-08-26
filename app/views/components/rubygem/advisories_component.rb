# frozen_string_literal: true

class Rubygem::AdvisoriesComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  SEVERITY_RANK = { "critical" => 0, "high" => 1, "moderate" => 2, "low" => 3 }.freeze
  HIGH_SEVERITIES = %w[critical high].freeze
  LINK = "text-orange-500 underline hover:text-orange-600 dark:text-orange-400 dark:hover:text-orange-300"

  def initialize(advisories:, version:)
    super()
    @advisories = advisories
    @version = version
  end

  def view_template
    list = affected_advisories
    return if list.empty?

    color, icon_color, icon = AlertComponent::STYLES.fetch(style_for(list))

    div(
      class: "flex flex-row items-start gap-3 p-4 rounded border text-b2 #{color}",
      data: { testid: "gem-advisories" }
    ) do
      icon_tag(icon, size: 8, class: "#{icon_color} shrink-0 h-8 w-8")
      div(class: "flex flex-col gap-3 min-w-0") do
        p(class: "font-semibold") { t("rubygems.advisories.title", count: list.size) }
        ul(class: "flex flex-col gap-3") do
          list.each { |advisory| advisory_item(advisory) }
        end
      end
    end
  end

  private

  def affected_advisories
    Array(@advisories)
      .select { |advisory| advisory.affects?(@version) }
      .sort_by { |advisory| [SEVERITY_RANK.fetch(advisory.severity, 4), advisory.identifier] }
  end

  def style_for(list)
    list.any? { |advisory| HIGH_SEVERITIES.include?(advisory.severity) } ? :error : :alert
  end

  def advisory_item(advisory)
    li(class: "flex flex-col gap-1") do
      div(class: "flex flex-wrap items-baseline gap-x-2 gap-y-1") do
        span(class: "font-semibold uppercase text-b4") { advisory.severity } if advisory.severity.present?
        span(class: "font-mono text-c4") { advisory.identifier }
        span(class: "text-b4") { "(#{advisory.aliases.join(', ')})" } if advisory.aliases.present?
      end
      p { advisory.summary }
      p do
        link_to t("rubygems.advisories.view_advisory"), advisory.url, class: LINK, target: "_blank", rel: "noopener"
      end
    end
  end
end

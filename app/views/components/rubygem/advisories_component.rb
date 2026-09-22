# frozen_string_literal: true

class Rubygem::AdvisoriesComponent < ApplicationComponent
  SEVERITY_RANK = { "critical" => 0, "high" => 1, "moderate" => 2, "low" => 3 }.freeze
  HIGH_SEVERITIES = %w[critical high].freeze
  SEVERITY_PILL = {
    "critical" => "bg-red-600 text-white dark:bg-red-500",
    "high" => "bg-orange-600 text-white dark:bg-orange-500",
    "moderate" => "bg-yellow-500 text-neutral-900 dark:bg-yellow-400",
    "low" => "bg-blue-600 text-white dark:bg-blue-500",
    "malware" => "bg-red-700 text-white dark:bg-red-600"
  }.freeze

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
      .sort_by { |advisory| [sort_rank(advisory), advisory.identifier] }
  end

  def sort_rank(advisory)
    return 0 if advisory.malware?

    SEVERITY_RANK.fetch(advisory.severity, 4)
  end

  def style_for(list)
    list.any? { |advisory| advisory.malware? || HIGH_SEVERITIES.include?(advisory.severity) } ? :error : :alert
  end

  def advisory_item(advisory)
    label = advisory_label(advisory)
    li(class: "flex flex-col gap-2 py-3 first:pt-0 last:pb-0") do
      div(class: "flex flex-wrap items-center gap-x-2 gap-y-1") do
        span(class: advisory_label_class(advisory)) { label } if label
        span(class: "font-mono text-c4") { advisory.identifier }
        span(class: "text-b4") { "(#{advisory.aliases.join(', ')})" } if advisory.aliases.present?
      end
      p { advisory.summary }

      div do
        render ButtonComponent.new(t("rubygems.advisories.view_advisory"), advisory.url, type: :link, size: :small, target: "_blank", rel: "noopener")
      end
    end
  end

  def advisory_label(advisory)
    return t("rubygems.advisories.malware") if advisory.malware?

    advisory.severity.presence
  end

  def advisory_label_class(advisory)
    pill_color = if advisory.malware?
                   SEVERITY_PILL.fetch("malware")
                 elsif advisory.severity.present?
                   SEVERITY_PILL.fetch(advisory.severity)
                 end

    "inline-flex items-center rounded-full px-2 py-0.5 text-b4 font-semibold uppercase #{pill_color}"
  end
end

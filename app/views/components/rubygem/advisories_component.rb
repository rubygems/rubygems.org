# frozen_string_literal: true

class Rubygem::AdvisoriesComponent < ApplicationComponent
  SEVERITY_RANK = { "critical" => 0, "high" => 1, "moderate" => 2, "low" => 3 }.freeze
  HIGH_SEVERITIES = %w[critical high].freeze
  SEVERITY_PILL = {
    "critical" => "border-red-700 bg-red-100 text-red-900 dark:border-red-300 dark:bg-red-950 dark:text-red-100",
    "high" => "border-orange-700 bg-orange-100 text-orange-900 dark:border-orange-300 dark:bg-orange-950 dark:text-orange-100",
    "moderate" => "border-yellow-700 bg-yellow-100 text-yellow-900 dark:border-yellow-300 dark:bg-yellow-950 dark:text-yellow-100",
    "low" => "border-blue-700 bg-blue-100 text-blue-900 dark:border-blue-300 dark:bg-blue-950 dark:text-blue-100",
    "malware" => "border-red-700 bg-red-100 text-red-900 dark:border-red-300 dark:bg-red-950 dark:text-red-100"
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
      class: "rounded border p-4 text-b2 #{color}",
      data: { testid: "gem-advisories" }
    ) do
      div(class: "flex items-start gap-3") do
        icon_tag(icon, size: 8, class: "#{icon_color} shrink-0 h-8 w-8")
        p(class: "flex min-h-8 min-w-0 flex-1 items-center text-b3 font-semibold sm:text-b2") do
          t("rubygems.advisories.title", count: list.size)
        end
      end
      div(class: "mt-4 flex min-w-0 flex-col gap-3 sm:ml-11") do
        ul(class: "flex flex-col gap-3", data: { testid: "primary-advisory" }) do
          advisory_item(list.first)
        end
        additional_advisories(list.drop(1)) if list.many?
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

  def severity_counts(advisories)
    counts = advisories.filter_map { |advisory| severity_key(advisory) }.tally

    div(
      class: "group-open/disclosure:hidden col-span-2 row-start-2 flex flex-wrap items-center gap-1.5 " \
             "sm:col-span-1 sm:col-start-2 sm:row-start-1 sm:justify-self-end",
      data: { testid: "advisory-severity-counts" }
    ) do
      counts.sort_by { |severity, _| severity_rank(severity) }.each do |severity, count|
        label = severity == "malware" ? t("rubygems.advisories.malware").downcase : severity
        span(class: "#{severity_pill_class(severity)} whitespace-nowrap") do
          t("rubygems.advisories.severity_count", count:, severity: label)
        end
      end
    end
  end

  def additional_advisories(advisories)
    details(
      class: "group/disclosure w-full border-t border-neutral-700/20 open:flex open:flex-col dark:border-neutral-200/20",
      data: { testid: "additional-advisories" }
    ) do
      summary(
        class: "group-open/disclosure:order-last group-open/disclosure:border-t group-open/disclosure:border-neutral-700/20 " \
               "group-open/disclosure:dark:border-neutral-200/20 grid w-full cursor-pointer list-none grid-cols-[1fr_auto] items-center " \
               "gap-x-3 gap-y-2 py-3 sm:grid-cols-[1fr_auto_auto] " \
               "text-b4 font-medium focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-orange-500 " \
               "[&::-webkit-details-marker]:hidden"
      ) do
        span(class: "group-open/disclosure:hidden") do
          t("rubygems.advisories.show_more", count: advisories.size)
        end
        span(class: "hidden group-open/disclosure:inline") { t("rubygems.advisories.show_fewer") }
        severity_counts(advisories)
        icon_tag(
          "keyboard-arrow-down",
          size: 5,
          class: "col-start-2 row-start-1 transition-transform group-open/disclosure:rotate-180 sm:col-start-3"
        )
      end
      ul(class: "flex flex-col divide-y divide-neutral-700/20 dark:divide-neutral-200/20") do
        advisories.each { |advisory| advisory_item(advisory, padded: true) }
      end
    end
  end

  def advisory_item(advisory, padded: false)
    label = advisory_label(advisory)
    li(class: classes("flex flex-col gap-2", padded && "py-4")) do
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
    "#{severity_pill_class(severity_key(advisory))} uppercase"
  end

  def severity_key(advisory)
    advisory.malware? ? "malware" : advisory.severity.presence
  end

  def severity_rank(severity)
    severity == "malware" ? 0 : SEVERITY_RANK.fetch(severity, 4)
  end

  def severity_pill_class(severity)
    "inline-flex items-center rounded-full border px-2 py-0.5 text-b4 font-semibold #{SEVERITY_PILL.fetch(severity)}"
  end
end

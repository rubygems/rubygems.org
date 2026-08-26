# frozen_string_literal: true

module VersionsHelper
  def version_date_tag(version, prefix: nil)
    tag.span(data: { testid: "version-date" }) do
      concat version_authored_date(version, prefix:)
      concat imported_version_tooltip if version.rely_on_built_at?
    end
  end

  def version_authored_date(version, prefix: nil)
    "#{prefix}#{nice_date_for(version.authored_at)}"
  end

  def version_number(version)
    tag.code(
      version.number,
      class: "px-2 text-c3 bg-green-200 dark:bg-green-800 rounded-sm text-neutral-900 dark:text-white"
    )
  end

  def version_date_component(version, **options)
    options[:class] = "flex text-b3 text-neutral-700 dark:text-neutral-400 #{options[:class]}"

    tag.div(**options) do
      concat version_authored_date(version)
      concat imported_version_tooltip if version.rely_on_built_at?
    end
  end

  def version_advisory?(advisories, version)
    Array(advisories).any? { |advisory| advisory.affects?(version) }
  end

  def download_count_component(rubygem, **options)
    downloads = number_with_delimiter(rubygem.downloads)
    options[:class] = "flex text-neutral-600 dark:text-neutral-400 text-nowrap text-b3 space-x-1 items-center #{options[:class]}"
    options[:title] = "#{t('total_downloads')}: #{downloads}"

    tag.span(**options) do
      concat icon_tag("arrow-circle-down", size: 5)
      concat tag.span(downloads)
    end
  end

  private

  def imported_version_tooltip
    render TooltipComponent.new(
      text: t("versions.index.imported_gem_version_notice", import_date: nice_date_for(Version::RUBYGEMS_IMPORT_DATE)),
      trigger_class: "text-orange-500"
    ) { tag.sup("*") }
  end
end

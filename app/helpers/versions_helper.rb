module VersionsHelper
  def version_date_tag(version, prefix: nil)
    data = {}
    klass = ["gem__version__date"]
    date = version_authored_date(version, prefix:)
    if version.rely_on_built_at?
      klass << "tooltip__text"
      data.merge!(tooltip: t("versions.index.imported_gem_version_notice", import_date: nice_date_for(Version::RUBYGEMS_IMPORT_DATE)))
    end

    content_tag(:small, class: klass, data: data) do
      concat date
      concat content_tag(:sup, "*") if version.rely_on_built_at?
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
    options[:class] = "flex text-b3 text-neutral-600 dark:text-neutral-400 #{options[:class]}"
    options[:data] ||= {}

    if version.rely_on_built_at?
      options[:data].merge!(tooltip: t("versions.index.imported_gem_version_notice", import_date: nice_date_for(Version::RUBYGEMS_IMPORT_DATE)))
    end

    tag.div(**options) do
      concat version_authored_date(version)
      concat content_tag(:sup, "*") if version.rely_on_built_at?
    end
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
end

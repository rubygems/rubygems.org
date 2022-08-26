module VersionsHelper
  def version_date_tag(version)
    data = {}
    klass = ["gem__version__date"]
    date = version_authored_date(version)
    if version.rely_on_built_at?
      klass << "tooltip__text"
      data.merge!(tooltip: t("versions.index.imported_gem_version_notice", import_date: nice_date_for(Version::RUBYGEMS_IMPORT_DATE)))
    end

    content_tag(:small, class: klass, data: data) do
      concat date
      concat content_tag(:sup, "*") if version.rely_on_built_at?
    end
  end

  def version_authored_date(version)
    "- #{nice_date_for(version.authored_at)}"
  end
end

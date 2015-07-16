module PagesHelper
  def version_number
    version.try(:number) || "0.0.0"
  end

  def version
    Rubygem.current_rubygems_release
  end

  def subtitle
    subtitle = "v#{version_number}"
    subtitle += " - #{nice_date_for(version.built_at)}" if version.try(:built_at)
    subtitle
  end
end

module PagesHelper
  def version_number
    version.try(:number) || "0.0.0"
  end

  def version
    Rubygem.current_rubygems_release
  end

  def subtitle
    subtitle = "v#{version_number}"
    subtitle += " - #{nice_date_for(version.created_at)}"
    subtitle
  end
end

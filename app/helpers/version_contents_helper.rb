module VersionContentsHelper
  def rubygem_version_contents_parent_path(path)
    return if path.blank?
    parent = Pathname.new(path).parent.to_s
    if parent == "."
      rubygem_version_contents_path(@rubygem.name, @latest_version.slug)
    else
      rubygem_version_content_path(@rubygem.name, @latest_version.slug, path: parent)
    end
  end

  def rubygem_version_contents_child_path(path, child)
    childpath = Pathname.new(path).join(child.chomp("/")).to_s
    rubygem_version_content_path(@rubygem.name, @latest_version.slug, path: childpath)
  end

  def folder_icon
    <<~SVG.html_safe
      <svg height="16" width="16" viewBox="0 0 16 16">
        <path d="M 2 1 L 0 3 v 11 L 1 15 h 14 L 16 14 v -10 L 15 3 H 10 L 8 1 Z"></path>
      </svg>
    SVG
  end

  def file_icon
    <<~SVG.html_safe
      <svg height="16" width="16" viewBox="0 0 16 16">
        <path d="M 3 0 L 2 1 v 13 L 3 15 h 10 L 14 14 v -11 L 11 0 Z M 4 2 H 10 L 12 4 V 13 H 4 V 2 Z"></path>
      </svg>
    SVG
  end
end

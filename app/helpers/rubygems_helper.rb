module RubygemsHelper
  def pluralized_licenses_header(version)
    t("rubygems.show.licenses_header").pluralize(version&.licenses&.length || 0)
  end

  def formatted_licenses(license_names)
    if license_names.blank?
      t("rubygems.show.no_licenses")
    else
      Array(license_names).join ", "
    end
  end

  def link_to_page(id, url)
    link_to(t(".links.#{id}"), url, rel: "nofollow", class: %w[gem__link t-list__item], id: id) if url.present?
  end

  def link_to_github(rubygem)
    if !rubygem.linkset.code.nil? && URI(rubygem.linkset.code).host == "github.com"
      URI(@rubygem.linkset.code)
    elsif !rubygem.linkset.home.nil? && URI(rubygem.linkset.home).host == "github.com"
      URI(rubygem.linkset.home)
    end
  rescue URI::InvalidURIError
    nil
  end

  def link_to_directory
    ("A".."Z").map do |letter|
      link_to(letter, rubygems_path(letter: letter), class: "gems__nav-link")
    end.join("\n").html_safe
  end

  def links_to_owners(rubygem)
    rubygem.owners.sort_by(&:id).inject("") { |link, owner| link << link_to_user(owner) }.html_safe
  end

  def links_to_owners_without_mfa(rubygem)
    rubygem.owners.without_mfa.sort_by(&:id).inject("") { |link, owner| link << link_to_user(owner) }.html_safe
  end

  def link_to_user(user)
    link_to gravatar(48, "gravatar-#{user.id}", user), profile_path(user.display_id),
      alt: user.display_handle, title: user.display_handle
  end

  def show_all_versions_link?(rubygem)
    rubygem.versions_count > 5 || rubygem.yanked_versions?
  end

  def latest_version_number(rubygem)
    return rubygem.version if rubygem.respond_to?(:version)
    (rubygem.latest_version || rubygem.versions.last)&.number
  end

  def github_params(link)
    "user=#{link.path.split('/').second}&repo=#{link.path.split('/').third}&type=star&count=true&size=large"
  end
end

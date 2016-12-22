module RubygemsHelper
  def pluralized_licenses_header(version)
    t("rubygems.show.licenses_header").pluralize(version.try(:licenses).try(:length) || 0)
  end

  def formatted_licenses(license_names)
    if license_names.blank?
      t("rubygems.show.no_licenses")
    else
      Array(license_names).join ", "
    end
  end

  def link_to_page(id, url)
    link_to(t(".links.#{id}"), url, rel: 'nofollow', class: ['gem__link', 't-list__item'], id: id) if url.present?
  end

  def link_to_github(rubygem)
    if !rubygem.linkset.code.nil? && URI(rubygem.linkset.code).host == "github.com"
      URI(@rubygem.linkset.code)
    elsif !rubygem.linkset.home.nil? && URI(rubygem.linkset.home).host == "github.com"
      URI(rubygem.linkset.home)
    end
  end

  def link_to_directory
    ("A".."Z").map do |letter|
      link_to(letter, rubygems_path(letter: letter), class: "gems__nav-link")
    end.join("\n").html_safe
  end

  def simple_markup(text)
    if text =~ /^==+ [A-Z]/
      options = RDoc::Options.new
      options.pipe = true
      sanitize RDoc::Markup.new.convert(text, RDoc::Markup::ToHtml.new(options))
    else
      content_tag :p, escape_once(sanitize(text.strip)), nil, false
    end
  end

  def atom_link(rubygem)
    link_to t(".links.rss"), rubygem_versions_path(rubygem, format: 'atom'),
      class: 'gem__link t-list__item', id: :rss
  end

  def download_link(version)
    link_to_page :download, "/downloads/#{version.full_name}.gem"
  end

  def documentation_link(version, linkset)
    return unless linkset.nil? || linkset.docs.blank?
    link_to_page :docs, version.documentation_path
  end

  def badge_link(rubygem)
    badge_url = "https://badge.fury.io/rb/#{rubygem.name}/install"
    link_to t(".links.badge"), badge_url, class: "gem__link t-list__item", id: :badge
  end

  def report_abuse_link(rubygem)
    encoded_title = URI.encode("Reporting Abuse on #{rubygem.name}")
    report_abuse_url = 'http://help.rubygems.org/discussion/new' \
      "?discussion[private]=1&discussion[title]=" + encoded_title
    link_to t(".links.report_abuse"), report_abuse_url.html_safe, class: 'gem__link t-list__item'
  end

  def link_to_pusher(handle)
    user = User.find_by_slug!(handle)
    link_to gravatar(48, "gravatar-#{user.id}", user), profile_path(user.display_id),
      alt: handle, title: handle
  end

  def links_to_owners(rubygem)
    rubygem.owners.sort_by(&:id).map do |owner|
      link_to gravatar(48, "gravatar-#{owner.id}", owner), profile_path(owner.display_id),
        alt: owner.display_handle, title: owner.display_handle
    end.join.html_safe
  end

  def nice_date_for(time)
    time.to_date.to_formatted_s(:long)
  end

  def show_all_versions_link?(rubygem)
    rubygem.versions_count > 5 || rubygem.yanked_versions?
  end

  def latest_version_number(rubygem)
    return rubygem.latest_version_number if rubygem.respond_to?(:latest_version_number)
    (rubygem.latest_version || rubygem.versions.last).try(:number)
  end
end

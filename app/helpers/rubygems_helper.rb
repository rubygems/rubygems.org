require 'rdoc'
require 'rdoc/markup'
require 'rdoc/markup/to_html'

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

  def link_to_page(text, url)
    link_to(text, url, rel: 'nofollow', class: ['gem__link', 't-list__item']) if url.present?
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
      RDoc::Markup.new.convert(text, RDoc::Markup::ToHtml.new(options)).html_safe
    else
      content_tag :p, escape_once(sanitize(text.strip)), nil, false
    end
  end

  def subscribe_link(rubygem)
    if signed_in?
      style = if rubygem.subscribers.find_by_id(current_user.id)
                'display:none'
              else
                'display:inline-block'
              end
      link_to t('.links.subscribe'), rubygem_subscription_path(rubygem),
        class: ['toggler', 'gem__link', 't-list__item'], id: 'subscribe',
        method: :post, remote: true, style: style
    else
      link_to t('.links.subscribe'), sign_in_path,
        class: [:toggler, 'gem__link', 't-list__item'], id: :subscribe
    end
  end

  def unsubscribe_link(rubygem)
    return unless signed_in?
    style = if rubygem.subscribers.find_by_id(current_user.id)
              'display:inline-block'
            else
              'display:none'
            end
    link_to t('.links.unsubscribe'), rubygem_subscription_path(rubygem),
      class: [:toggler, 'gem__link', 't-list__item'], id: 'unsubscribe',
      method: :delete, remote: true, style: style
  end

  def atom_link(rubygem)
    link_to t(".links.rss"), rubygem_versions_path(rubygem, format: 'atom'),
      class: 'gem__link t-list__item', id: :rss
  end

  def download_link(version)
    link_to t('.links.download'), "/downloads/#{version.full_name}.gem",
      class: 'gem__link t-list__item', id: :download
  end

  def documentation_link(version, linkset)
    return unless linkset.nil? || linkset.docs.blank?
    link_to t('.links.docs'), version.documentation_path,
      class: 'gem__link t-list__item', id: :docs
  end

  def badge_link(rubygem)
    badge_url = "https://badge.fury.io/rb/#{rubygem.name}/install"
    link_to t(".links.badge"), badge_url, class: "gem__link t-list__item", id: :badge
  end

  def report_abuse_link(rubygem)
    encoded_title = URI.encode("Reporting Abuse on #{rubygem.name}")
    report_abuse_url = "http://help.rubygems.org/discussion/new?discussion[private]=1&discussion[title]=" + encoded_title # rubocop:disable Metrics/LineLength
    link_to t(".links.report_abuse"), report_abuse_url.html_safe, class: 'gem__link t-list__item'
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
    rubygem.versions.most_recent.try(:number)
  end
end

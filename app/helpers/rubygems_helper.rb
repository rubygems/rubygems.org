module RubygemsHelper
  def formatted_licenses(license_names)
    if license_names.blank?
      t("rubygems.show.no_licenses")
    else
      Array(license_names).join ", "
    end
  end

  def link_to_page(text, url)
    link_to(text, url, :rel => 'nofollow', :class => ['gem__link', 't-list__item']) if url.present?
  end

  def link_to_directory
    ("A".."Z").map do |letter|
      link_to(letter, rubygems_path(:letter => letter), :class => "gems__nav-link")
    end.join("\n").html_safe
  end

  def simple_markup(text)
    if text =~ /^==+ [A-Z]/
      RDoc::Markup.new.convert(text, RDoc::Markup::ToHtml.new).html_safe
    else
      content_tag :p, escape_once(sanitize(text.strip)), nil, false
    end
  end

  def subscribe_link(rubygem)
    if signed_in?
      link_to 'Subscribe', rubygem_subscription_path(rubygem),
        :remote => true,
        :method => :post,
        :id     => 'subscribe',
        :class  => ['toggler', 'gem__link', 't-list__item'],
        :style  => rubygem.subscribers.find_by_id(current_user.try(:id)) ? 'display:none' : 'display:inline-block'
    else
      link_to 'Subscribe', sign_in_path, :id => :subscribe, :class => [:toggler, 'gem__link', 't-list__item']
    end
  end

  def unsubscribe_link(rubygem)
    if signed_in?
      link_to 'Unsubscribe', rubygem_subscription_path(rubygem),
        :remote  => true,
        :method  => :delete,
        :id    => 'unsubscribe',
        :class  => [:toggler, 'gem__link', 't-list__item'],
        :style => rubygem.subscribers.find_by_id(current_user.try(:id)) ? 'display:inline-block' : 'display:none'
    end
  end

  def atom_link(rubygem)
    link_to 'RSS', rubygem_versions_path(rubygem, format: 'atom'), :id => :rss, :class => 'gem__link t-list__item'
  end

  def download_link(version)
    link_to "Download", "/downloads/#{version.full_name}.gem", :id => :download, :class => 'gem__link t-list__item'
  end

  def documentation_link(version, linkset)
    link_to 'Documentation', version.documentation_path, :class => 'gem__link t-list__item', :id => :docs if linkset.nil? || linkset.docs.blank?
  end

  def badge_link(rubygem)
    badge_url = "http://badge.fury.io/rb/#{rubygem.name}/install"
    link_to "Badge", badge_url, :id => :badge, :class => "gem__link t-list__item"
  end

  def report_abuse_link(rubygem)
    report_abuse_url = "http://help.rubygems.org/discussion/new?discussion[title]=Reporting%20Abuse%20on%20#{CGI.escape(rubygem.name)}&discussion[private]=1".html_safe
    link_to 'Report Abuse', report_abuse_url, :class => 'gem__link t-list__item'
  end

  def links_to_owners(rubygem)
    rubygem.owners.sort_by(&:id).map do |owner|
      link_to gravatar(48, "gravatar-#{owner.id}", owner), profile_path(owner.display_id),
        :alt => owner.display_handle, :title => owner.display_handle
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

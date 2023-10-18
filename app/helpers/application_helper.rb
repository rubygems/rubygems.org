module ApplicationHelper
  def page_title
    combo = "#{t :title} | #{t :subtitle}"
    # If instance variable @title_for_header_only is present then it is added to combo title string
    combo = "#{@title_for_header_only} | #{combo}" if @title_for_header_only.present?
    @title.present? ? "#{@title} | #{combo}" : combo
  end

  def atom_feed_link(title, url)
    tag.link(rel: "alternate",
                type: "application/atom+xml",
                href: url,
                title: title)
  end

  def short_info(rubygem)
    info = gem_info(rubygem).strip.truncate(90)
    escape_once(sanitize(info))
  end

  def gem_info(rubygem)
    if rubygem.respond_to?(:description)
      [rubygem.summary, rubygem.description, "This rubygem does not have a description or summary."].find(&:present?)
    else
      version = rubygem.latest_version || rubygem.versions.last
      version.info
    end
  end

  def avatar(size, id = "gravatar", user = current_user, theme: :light, **options)
    url = user.gravatar_url(size: size, secure: true) || default_avatar(theme: theme)
    image_tag url,
      id: id,
      width: size,
      height: size,
      **options
  end

  def download_count(rubygem)
    number_with_delimiter(rubygem.downloads)
  end

  def stats_graph_meter(gem, count)
    gem.downloads * 1.0 / count * 100
  end

  def search_form_class
    if [root_path, advanced_search_path].include? request.path_info
      "header__search-wrap--home"
    else
      "header__search-wrap"
    end
  end

  def active?(path)
    "is-active" if request.path_info == path
  end

  # replacement for Kaminari::ActionViewExtension#paginate
  # only shows `next` and `prev` links and not page numbers, saving a COUNT(DISTINCT ..) query
  def plain_paginate(items)
    render "layouts/plain_paginate", items: items
  end

  def content_for_title(title, title_url)
    return title unless title_url
    link_to title, title_url, class: "t-link--black"
  end

  def flash_message(name, msg)
    return sanitize(msg) if name.end_with? "html"
    msg
  end

  private

  def default_avatar(theme:)
    case theme
    when :light then "/images/avatar.svg"
    when :dark then "/images/avatar_inverted.svg"
    else raise "invalid default avatar theme, only light and dark are suported"
    end
  end
end

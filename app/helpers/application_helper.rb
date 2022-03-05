module ApplicationHelper
  def page_title
    combo = "#{t :title} | #{t :subtitle}"
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
      [rubygem.description, rubygem.summary, "This rubygem does not have a description or summary."].find(&:present?)
    else
      version = rubygem.latest_version || rubygem.versions.last
      version.info
    end
  end

  def gravatar(size, id = "gravatar", user = current_user)
    image_tag user.gravatar_url(size: size, secure: request.ssl?).html_safe,
      id: id,
      width: size,
      height: size
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

  def i18n_api_scopes(api_key)
    api_key.enabled_scopes.sum("") { |scope| tag.ul(t(scope, scope: %i[api_keys index]), class: "scopes__list") }
  end
end

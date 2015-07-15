module ApplicationHelper
  def page_title
    combo = "#{t :title} | #{t :subtitle}"
    if @title
      "#{@title} | #{combo}"
    else
      combo
    end
  end

  def atom_feed_link(title, url)
    tag 'link', rel: 'alternate',
                type: 'application/atom+xml',
                href: url,
                title: title
  end

  def short_info(version)
    info = version.info.strip.truncate(90)
    escape_once(sanitize(info))
  end

  def gravatar(size, id = "gravatar", user = current_user)
    image_tag(user.gravatar_url(size: size, secure: request.ssl?).html_safe, id: id, width: size, height: size)
  end

  def download_count(rubygem)
    number_with_delimiter(rubygem.downloads)
  end

  def stats_graph_meter(gem, count)
    decimal = gem.downloads * 1.0 / count
    decimal * 100
  end
end

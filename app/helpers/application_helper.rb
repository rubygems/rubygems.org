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

  # Generate an appropriate profile image URL for a user.
  #
  # @param user [User] A user to generate a Gravatar URL for
  # @param options [Hash]
  # @option options [Integer] :size ({Gravatar::DEFAULT_SIZE}) Desired pixel to request for the referenced Gravatar image
  # @return [ActiveSupport::SafeBuffer] A profile image URL
  def gravatar_url(user:, **options)
    size = options.fetch(:size, Gravatar::DEFAULT_SIZE)
    Gravatar.new(user, size: size).url.html_safe
  end

  # Generate an appropriate profile image markup for a user.
  #
  # @param user [User] A user to generate a Gravatar image for
  # @param size [Integer] ({Gravatar::DEFAULT_SIZE}) Desired dimensions of the generated Gravatar image
  # @param html_options [Hash] HTML options, see {https://api.rubyonrails.org/classes/ActionView/Helpers/TagHelper.html#method-i-content_tag ActionView::Helpers::TagHelper#content_tag}
  # @option html_options [String] :id ('gravatar') HTML 'id' attribute
  # @return [ActiveSupport::SafeBuffer] Profile image markup
  def gravatar_image_tag(user:, size:, **html_options)
    gravatar = Gravatar.new(user, size: size)
    size ||= Gravatar::DEFAULT_SIZE

    # Set a default ID if one hasn't been provided
    id = html_options.fetch(:id, "gravatar")

    image_tag(
      gravatar.url.html_safe,
      html_options.merge(id: id, width: size, height: size))
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
end

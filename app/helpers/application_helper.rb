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
    tag 'link', :rel   => 'alternate',
                :type  => 'application/atom+xml',
                :href  => url,
                :title => title
  end

  def short_info(version)
    truncate(version.info, :length => 90)
  end

  def gravatar(size, id = "gravatar", user = current_user)
    image_tag(user.gravatar_url(:size => size, :secure => request.ssl?).html_safe, :id => id, :width => size, :height => size)
  end

  def ssl_url_for(options = {})
    if SimpleSSLRequirement::SSL_ENVIRONMENTS.include?(Rails.env)
      protocol = 'https'  # when using simple_ssl_requirement
    else
      protocol = 'http'   # for development
    end
    options.reverse_merge!({:only_path => false, :protocol => protocol})
    url_for(options)
  end

  def download_count(rubygem)
    number_with_delimiter(rubygem.downloads)
  end
end

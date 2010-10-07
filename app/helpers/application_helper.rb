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
    truncate(version.info, :length => 100)
  end

  def gravatar(size, id = "gravatar")
    image_tag(current_user.gravatar_url(:size => size, :secure => request.ssl?), :id => id)
  end
end

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def title
    "gemcutter"
  end

  def subtitle
    "awesome gem hosting"
  end

  def page_title
    combo = "#{title} | #{subtitle}"
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
end

module ApplicationHelper
  # Remove once 2.3.4 comes out!
  # https://rails.lighthouseapp.com/projects/8994/tickets/1311-add-content_forname-helper
  def content_for?(name)
    instance_variable_get("@content_for_#{name}").present?
  end

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
end

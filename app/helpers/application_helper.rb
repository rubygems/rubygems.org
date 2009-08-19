module ApplicationHelper
  # Remove once 2.3.4 comes out!
  # https://rails.lighthouseapp.com/projects/8994/tickets/1311-add-content_forname-helper
  def content_for?(name)
    instance_variable_get("@content_for_#{name}").present?
  end

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
end

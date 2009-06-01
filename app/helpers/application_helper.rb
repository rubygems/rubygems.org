# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def title
    "gemcutter"
  end

  def subtitle
    "kickass gem hosting"
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

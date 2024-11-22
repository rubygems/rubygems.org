# frozen_string_literal: true

class CardComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  def view_template(&)
    color = "bg-white dark:bg-black border border-neutral-200 dark:border-neutral-800 text-neutral-900 dark:text-white "
    box = "w-full px-4 py-6 md:p-10 mb-10 rounded-md shadow overflow-hidden"
    article(**classes(color, box), &)
  end

  def head(title = nil, icon: nil, count: nil, url: nil, **options, &block)
    block ||= proc do
      title(title, icon:, count:)
      a(href: url, class: "text-sm text-orange-500 hover:underline") { t("view_all") } if url
    end
    options[:class] = "#{options[:class]} flex justify-between items-center -mx-10 px-10 pb-8"
    div(**options, &block)
  end

  def title(title, icon: nil, count: nil)
    h3(class: "flex items-center text-lg space-x-2") do
      render_icon(icon, class: "fill-orange") if icon
      span(class: "font-semibold") { title }
      # when count is 0, don't show the count because it's more confusing than helpful
      span(class: "font-light text-neutral-600") { count } unless count.to_i.zero?
    end
  end

  def list(**options, &)
    options[:class] = "#{options[:class]} -mx-4"
    ul(**options, &)
  end

  def divided_list(**options, &)
    options[:class] = "#{options[:class]} -mx-4 divide-y divide-neutral-200 dark:divide-neutral-800"
    ul(**options, &)
  end

  def list_item(**options, &)
    options[:class] = "#{options[:class]} #{LIST_ITEM_CLASSES}"
    li do
      div(**options, &)
    end
  end

  def list_item_to(url = nil, **options, &)
    options[:class] = "#{options[:class]} #{LIST_ITEM_CLASSES}"
    li do
      link_to(url, **options) do
        span(class: "flex-1", &)
        render_icon("arrow-forward-ios", class: "w-8 h-8 ml-2 -mr-2 text-neutral-800 dark:text-white fill-current")
      end
    end
  end

  # removes padding inside the "content" area of the card so scroll bar and overflaw appear correctly
  # adds a border to the top of the scrollable area to explain the content being hidden on scroll
  def scrollable(**options, &)
    options[:class] = "#{options[:class]} lg:max-h-96 lg:overflow-y-auto " \
                      "-mx-4 -mb-6 md:-mx-10 md:-mb-10 " \
                      "border-t border-neutral-200 dark:border-neutral-800"
    div(**options) do
      div(class: "px-4 pt-6 md:px-10 md:pt-10", &)
    end
  end

  private

  LIST_ITEM_CLASSES = "flex w-full px-4 py-3 " \
                      "items-center md:rounded " \
                      "hover:bg-neutral-100 dark:hover:bg-neutral-800"

  def render_icon(name, size: 8, **)
    unsafe_raw helpers.icon_tag(name, size: size, **)
  end
end

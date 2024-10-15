# frozen_string_literal: true

class CardComponent < ApplicationComponent
  def view_template(&)
    color = "bg-white dark:bg-black border border-neutral-400 dark:border-neutral-800 rounded-md shadow text-neutral-900 dark:text-neutral-100"
    box = "w-full px-4 py-6 md:p-10"
    article(**classes(color, box), &)
  end

  def head(title, icon: nil, url: nil, count: nil)
    div(class: "flex justify-between items-center mb-8") do
      h3(class: "flex items-center space-x-2 text-lg") do
        render_icon(icon) if icon
        span(class: "font-semibold") { title }
        span(class: "font-light text-neutral-600") { count } if count
      end

      a(href: url, class: "text-sm text-orange-500 hover:underline") { t("view_all") } if url
    end
  end

  def with_list(items, &)
    ul(class: "mx-6 my-8") do
      items.each do |item|
        li(class: "flex justify-between items-center py-3 px-4 rounded-md border border-white dark:border-neutral-850 hover:border-neutral-700") do
          yield(item)
        end
      end
    end
  end

  def with_content(&)
    div(class: "space-y-4", &)
  end

  private

  def render_icon(name, width: 32, height: 32)
    svg(class: "fill-orange", width:, height:) do
      "<use href=\"/images/icons.svg##{name}\"/>".html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end

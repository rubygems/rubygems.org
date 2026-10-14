# frozen_string_literal: true

# The "Sort: …" dropdown above a gem list. Each choice links to the current page
# with ?sort= set (and pagination reset); GemSortable remembers it in a cookie.
class GemSortComponent < ApplicationComponent
  prop :current
  prop :options

  def view_template
    render DropdownComponent.new(label: t(".label", sort: option_label(@current)), menu_label: t(".menu_label"),
                                 fallback: method(:sort_form)) do |menu|
      @options.each do |sort|
        menu.item_to option_label(sort), sort_path(sort), checked: sort == @current
      end
    end
  end

  private

  def sort_form
    request = view_context.request
    form(action: request.path, method: "get", class: "flex flex-wrap items-end gap-2") do
      # GET forms replace the URL query. Keep its nested keys and repeated values,
      # but never submit the old sort or page alongside the new selection.
      URI.decode_www_form(request.query_parameters.except("page", "sort").to_query).each do |name, value|
        input(type: "hidden", name:, value:)
      end
      label(class: "flex flex-col gap-1 text-b3 text-neutral-800 dark:text-white") do
        span { t(".menu_label") }
        select(name: "sort", class: "h-9 rounded border border-neutral-300 dark:border-neutral-700 bg-white dark:bg-black px-2") do
          @options.each do |sort|
            option(value: sort, selected: sort == @current) { option_label(sort) }
          end
        end
      end
      button(type: "submit", class: DropdownComponent::BUTTON) { t(".apply") }
    end
  end

  def option_label(sort)
    t(".options.#{sort}")
  end

  def sort_path(sort)
    request = view_context.request
    query = request.query_parameters.except("page").merge("sort" => sort)
    "#{request.path}?#{query.to_query}"
  end
end

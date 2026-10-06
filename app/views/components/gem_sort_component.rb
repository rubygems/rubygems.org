# frozen_string_literal: true

# The "Sort: …" dropdown above a gem list. Each choice links to the current page
# with ?sort= set (and pagination reset); GemSortable remembers it in a cookie.
class GemSortComponent < ApplicationComponent
  prop :current
  prop :options

  def view_template
    render DropdownComponent.new(label: t(".label", sort: option_label(@current)), menu_label: t(".menu_label")) do |menu|
      @options.each do |sort|
        menu.item_to option_label(sort), sort_path(sort), checked: sort == @current
      end
    end
  end

  private

  def option_label(sort)
    t(".options.#{sort}")
  end

  def sort_path(sort)
    request = view_context.request
    query = request.query_parameters.except("page").merge("sort" => sort)
    "#{request.path}?#{query.to_query}"
  end
end

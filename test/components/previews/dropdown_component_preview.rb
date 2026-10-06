# frozen_string_literal: true

class DropdownComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  # @param label text "button text"
  # @param menu_label text "menu accessible name"
  def default(label: "Sort: Number of downloads", menu_label: "Sort gems by")
    render DropdownComponent.new(label:, menu_label:) do |menu|
      menu.item_to "Most recently published", "#recent", checked: false
      menu.item_to "Number of downloads", "#downloads", checked: true
      menu.item_to "Alphabetical", "#name", checked: false
    end
  end
end

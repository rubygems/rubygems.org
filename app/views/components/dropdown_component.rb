# frozen_string_literal: true

# A button that opens a menu of choices (the WAI-ARIA "menu button" pattern).
#
#   render DropdownComponent.new(label: "Sort: Name", menu_label: "Sort gems by") do |menu|
#     menu.item_to "Name", "?sort=name", checked: true
#     menu.item_to "Downloads", "?sort=downloads", checked: false
#   end
#
# The menu is a native popover, so it renders above clipping containers such as
# cards, and closes on Escape or an outside click. The dropdown-menu controller
# adds positioning, aria-expanded and arrow-key navigation.
class DropdownComponent < ApplicationComponent
  prop :label
  prop :menu_label
  prop :id, default: -> { "dropdown-#{SecureRandom.alphanumeric(10)}" }

  def view_template(&)
    div(class: "inline-flex", data: { controller: "dropdown-menu", action: "resize@window->dropdown-menu#position" }) do
      button(
        type: "button",
        id: button_id,
        popovertarget: menu_id,
        class: BUTTON,
        aria: { haspopup: "menu", expanded: "false", controls: menu_id },
        data: { dropdown_menu_target: "button", action: "keydown->dropdown-menu#buttonKeydown" }
      ) do
        span { @label }
        icon_tag("arrow-drop-down", size: 5)
      end

      div(
        id: menu_id,
        popover: "auto",
        role: "menu",
        aria: { label: @menu_label },
        class: MENU,
        data: {
          dropdown_menu_target: "menu",
          action: "beforetoggle->dropdown-menu#position toggle->dropdown-menu#toggled keydown->dropdown-menu#menuKeydown"
        },
        &
      )
    end
  end

  # A choice that navigates to url. Exactly one item in a menu should be checked.
  def item_to(text, url, checked:)
    a(
      href: url,
      role: "menuitemradio",
      tabindex: "-1",
      aria: { checked: checked.to_s },
      class: ITEM,
      data: { dropdown_menu_target: "item", action: "click->dropdown-menu#close" }
    ) do
      span { text }
      icon_tag("check", size: 5, class: checked ? "text-orange" : "invisible")
    end
  end

  private

  def button_id = "#{@id}-button"
  def menu_id = "#{@id}-menu"

  BUTTON = "inline-flex items-center gap-1 h-9 pl-3 pr-2 rounded border border-neutral-300 dark:border-neutral-700 " \
           "bg-white dark:bg-black text-b3 text-neutral-800 dark:text-white text-nowrap " \
           "hover:bg-neutral-100 dark:hover:bg-neutral-800 aria-expanded:bg-neutral-100 dark:aria-expanded:bg-neutral-800 " \
           "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-orange"
  MENU = "dropdown-menu absolute inset-auto m-0 w-max p-2 rounded-lg " \
         "bg-white dark:bg-black border border-neutral-200 dark:border-neutral-800 shadow-xl shadow-black/10 " \
         "text-b2 text-left text-neutral-900 dark:text-white"
  ITEM = "flex items-center justify-between gap-4 px-3 py-3 rounded text-nowrap " \
         "hover:bg-neutral-100 dark:hover:bg-neutral-800 focus:bg-neutral-100 dark:focus:bg-neutral-800 " \
         "focus-visible:outline focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-orange " \
         "aria-checked:font-semibold"
end

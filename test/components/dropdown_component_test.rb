# frozen_string_literal: true

require "test_helper"

class DropdownComponentTest < ComponentTest
  setup do
    render DropdownComponent.new(label: "Sort: Name", menu_label: "Sort gems by", id: "sort") do |menu|
      menu.item_to "Downloads", "/gems?sort=downloads", checked: false
      menu.item_to "Name", "/gems?sort=name", checked: true
    end
  end

  should "name the button by its label and point it at the menu it opens" do
    assert_selector "button#sort-button[type='button'][popovertarget='sort-menu']", text: "Sort: Name"
    assert_selector "button[aria-haspopup='menu'][aria-expanded='false'][aria-controls='sort-menu']"
  end

  should "render a closed, named menu" do
    assert_selector "#sort-menu[role='menu'][popover='auto'][aria-label='Sort gems by']", visible: :all
  end

  should "render items as radio choices with the checked one marked, out of the tab order" do
    items = page.all("#sort-menu [role='menuitemradio']", visible: :all)

    assert_equal ["/gems?sort=downloads", "/gems?sort=name"], items.pluck(:href)
    assert_equal %w[false true], items.pluck(:"aria-checked")
    assert_equal %w[-1 -1], items.pluck(:tabindex)
  end

  should "hide the decorative icons from assistive technology" do
    assert_no_selector "svg:not([aria-hidden='true'])", visible: :all
  end

  should "generate a unique id per instance" do
    ids = Array.new(2).map do
      render DropdownComponent.new(label: "Sort", menu_label: "Sort") { nil }
      page.first("[role='menu']", visible: :all)[:id]
    end

    assert_equal 2, ids.uniq.size
  end
end

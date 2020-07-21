require "test_helper"

class OwnershipCallsTest < SystemTest
  include ActionMailer::TestHelper

  setup do
    @owner = create(:user)
  end

  test "ownership calls listing and pagination on index" do
    gems = create_list(:rubygem, 15, owners: [@owner], number: "1.0.0")
    gems.each do |gem|
      create(:ownership_call, rubygem: gem, user: @owner)
    end
    visit ownership_calls_path

    assert_title "Ownership Calls"
    assert_selector :css, ".gems__meter", text: "Displaying ownership calls 1 - 10 of 15 in total"
    assert_selector :css, ".gems__gem", count: 10
  end

  test "shows no calls notice if call doesn't exist" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    visit rubygem_adoptions_path(rubygem, as: user)

    assert page.has_content? "There are no ownership calls for #{rubygem.name}"
  end

  test "create ownership call as owner" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    visit rubygem_path(rubygem, as: @owner)

    within ".gem__aside > div.t-list__items" do
      click_link "Adoption"
    end

    assert page.has_field? "Note"
    create_call("call about _note_ by *owner*.")

    assert_selector :css, "div.gems__gem__info > a.gems__gem__name", text: rubygem.name
    assert_selector :css, "div.ownership__details > p", text: "call about note by owner."
  end

  test "shows correct data and formatting about call if exists" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0", downloads: 2_000)
    create(:ownership_call, rubygem: rubygem, user: @owner, note: "note _italics_ *bold*.")
    user = create(:user)
    visit rubygem_adoptions_path(rubygem, as: user)

    assert page.has_link? rubygem.name, href: rubygem_path(rubygem)
    assert page.has_link? @owner.handle, href: profile_path(@owner)
    within "div.ownership__details" do
      assert page.has_css? "em", text: "italics"
      assert page.has_css? "strong", text: "bold"
    end
    assert_selector :css, "p.gems__gem__downloads__count", text: "2,000 Downloads"
  end

  test "ownership call of less popular gem as user" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    user = create(:user)
    visit rubygem_path(rubygem, as: user)

    within ".gem__aside > div.t-list__items" do
      click_link "Adoption"
    end

    assert page.has_content? "There are no ownership calls for #{rubygem.name}"
    assert page.has_field? "Ownership Request"
    assert page.has_button? "Create"
  end

  test "hide adoptions link if popular gem" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0", downloads: 20_000)
    user = create(:user)
    visit rubygem_path(rubygem, as: user)

    refute page.has_selector? "a[href='#{rubygem_adoptions_path(rubygem)}']"
  end

  test "show adoptions link if less popular gem" do
    user = create(:user)
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    create(:ownership_call, rubygem: rubygem, user: @owner)

    visit rubygem_path(rubygem, as: user)
    within ".gem__aside > div.t-list__items" do
      assert_selector :css, "a[href='#{rubygem_adoptions_path(rubygem)}']"
    end
  end

  test "show adoptions link if owner" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0", downloads: 20_000)
    create(:ownership_call, rubygem: rubygem, user: @owner)

    visit rubygem_path(rubygem, as: @owner)
    within ".gem__aside > div.t-list__items" do
      assert_selector :css, "a[href='#{rubygem_adoptions_path(rubygem)}']"
    end
  end

  test "close ownership call" do
    rubygem = create(:rubygem, owners: [@owner], number: "1.0.0")
    ownership_call = create(:ownership_call, rubygem: rubygem, user: @owner)
    create_list(:ownership_request, 3, :with_ownership_call, rubygem: rubygem, ownership_call: ownership_call)

    visit rubygem_adoptions_path(rubygem, as: @owner)
    within first("form.button_to") do
      click_button "Close"
    end

    Delayed::Worker.new.work_off
    assert_emails 3
  end

  private

  def create_call(note)
    fill_in "Note", with: note
    click_button "Create"
  end
end

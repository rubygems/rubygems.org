require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  include SearchKickHelper

  test "searching for a gem" do
    create(:rubygem, name: "LDAP", number: "1.0.0")
    create(:rubygem, name: "LDAP-PLUS", number: "1.0.0")
    import_and_refresh

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert_text "LDAP"

    assert_text "LDAP-PLUS"
  end

  test "searching for a yanked gem" do
    rubygem = create(:rubygem, name: "LDAP")
    create(:version, rubygem: rubygem, indexed: false)
    import_and_refresh

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert_text "NO GEMS FOUND"
    assert_text "YANKED (1)"

    click_link "Yanked (1)"

    assert_text "LDAP"
    assert page.has_selector? "a[href='#{rubygem_path('LDAP')}']"
  end

  test "searching for a gem with yanked versions" do
    rubygem = create(:rubygem, name: "LDAP")
    create(:version, rubygem: rubygem, number: "1.1.1", indexed: true)
    create(:version, rubygem: rubygem, number: "2.2.2", indexed: false)
    import_and_refresh

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert_text("1.1.1")
    assert_no_text("2.2.2")
  end

  test "params has non white listed keys" do
    Kaminari.configure { |c| c.default_per_page = 1 }
    create(:rubygem, name: "ruby-ruby", number: "1.0.0")
    create(:rubygem, name: "ruby-gems", number: "1.0.0")
    import_and_refresh

    visit "/search?query=ruby&original_script_name=javascript:alert(1)//&script_name=javascript:alert(1)//"

    assert_text "ruby-ruby"
    assert page.has_link?("Next", href: "/search?page=2&query=ruby")
    Kaminari.configure { |c| c.default_per_page = 30 }
  end

  test "total result count more than (max pages x default per page) shows max pages and accurate total count" do
    silence_warnings do
      Kaminari.configure { |c| c.default_per_page = 1 }
      orignal_val = Gemcutter::SEARCH_MAX_PAGES
      Gemcutter::SEARCH_MAX_PAGES = 2

      create(:rubygem, name: "ruby-ruby", number: "1.0.0")
      create(:rubygem, name: "ruby-gems", number: "1.0.0")
      create(:rubygem, name: "ruby-thing", number: "1.0.0")
      import_and_refresh

      visit "/search?query=ruby"

      assert_text "DISPLAYING GEM 1 - 1 OF 3 IN TOTAL"

      click_link "Last"

      assert_text "DISPLAYING GEM 2 - 2 OF 3 IN TOTAL"

      Gemcutter::SEARCH_MAX_PAGES = orignal_val
      Kaminari.configure { |c| c.default_per_page = 30 }
    end
  end

  test "searching for reverse dependencies" do
    dependency = create(:rubygem)
    create(:version, rubygem: dependency)

    gem = create(:rubygem)
    version_one = create(:version, rubygem: gem)
    create(:dependency, :runtime, version: version_one, rubygem: dependency)

    visit "/gems/#{dependency.name}/reverse_dependencies"

    assert_text "Search reverse dependencies Gems…"
    within ".reverse__dependencies" do
      assert_text gem.name
    end

    visit "/gems/#{gem.name}/reverse_dependencies"

    assert_no_text "Search reverse dependencies Gems…"
    assert_text "This gem has no reverse dependencies"
  end
end

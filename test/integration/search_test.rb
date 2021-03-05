require "test_helper"

class SearchTest < SystemTest
  include ESHelper

  test "searching for a gem" do
    create(:rubygem, name: "LDAP", number: "1.0.0")
    create(:rubygem, name: "LDAP-PLUS", number: "1.0.0")
    import_and_refresh

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert page.has_content? "LDAP"

    assert page.has_content? "LDAP-PLUS"
  end

  test "searching for a yanked gem" do
    rubygem = create(:rubygem, name: "LDAP")
    create(:version, rubygem: rubygem, indexed: false)
    import_and_refresh

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert page.has_content? "No gems found"
    assert page.has_content? "Yanked (1)"

    click_link "Yanked (1)"
    assert page.has_content? "LDAP"
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

    assert page.has_content?("1.1.1")
    refute page.has_content?("2.2.2")
  end

  test "search page with a non valid format" do
    assert_raises(ActionController::RoutingError) do
      get search_path(format: :json), params: { query: "foobar" }
    end
  end

  test "params has non white listed keys" do
    Kaminari.configure { |c| c.default_per_page = 1 }
    create(:rubygem, name: "ruby-ruby", number: "1.0.0")
    create(:rubygem, name: "ruby-gems", number: "1.0.0")
    import_and_refresh

    visit "/search?query=ruby&original_script_name=javascript:alert(1)//&script_name=javascript:alert(1)//"
    assert page.has_content? "ruby-ruby"
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
      assert page.has_content? "Displaying gem 1 - 1 of 3 in total"

      click_link "Last"
      assert page.has_content? "Displaying gem 2 - 2 of 3 in total"

      Gemcutter::SEARCH_MAX_PAGES = orignal_val
      Kaminari.configure { |c| c.default_per_page = 30 }
    end
  end
end

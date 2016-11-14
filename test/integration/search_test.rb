require 'test_helper'

class SearchTest < SystemTest
  test "searching for a gem" do
    create(:rubygem, name: "LDAP", number: "1.0.0")
    create(:rubygem, name: "LDAP-PLUS", number: "1.0.0")

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert page.has_content? "LDAP"
    assert page.has_content? "Exact match"

    assert page.has_content? "LDAP-PLUS"
  end

  test "searching for a yanked gem" do
    rubygem = create(:rubygem, name: "LDAP")
    create(:version, rubygem: rubygem, indexed: false)

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert page.has_content? "No gems found"
  end

  test "searching for a gem with yanked versions" do
    rubygem = create(:rubygem, name: "LDAP")
    create(:version, rubygem: rubygem, number: "1.1.1", indexed: true)
    create(:version, rubygem: rubygem, number: "2.2.2", indexed: false)
    create(:version, rubygem: rubygem, number: "3.3.3", indexed: true)

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert page.has_content?("1.1.1")
    refute page.has_content?("2.2.2")
    assert page.has_content?("3.3.3")
  end

  test "search page with a non valid format" do
    assert_raises(ActionController::RoutingError) do
      get search_path(format: :json), query: 'foobar'
    end
  end

  setup do
    3.times do |i|
      rubygem = create(:rubygem, name: "ruby#{i}", number: '1.0.0')
      rubygem.gem_download.update(count: i)
    end
    Rubygem.per_page = 2
  end
  teardown { Rubygem.per_page = 30 }

  test "params has non white listed keys" do
    visit '/search?query=ruby&script_name=javascript:alert(1)//'
    refute page.has_content? "ruby0"
    assert page.has_content? "ruby1"
    assert page.has_content? "ruby2"
    assert page.has_link?("Next", href: "/search?page=2&query=ruby")
  end
end

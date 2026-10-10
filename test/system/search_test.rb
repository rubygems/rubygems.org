# frozen_string_literal: true

require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  include SearchKickHelper

  test "searching for a gem" do
    create(:rubygem, :reindex, name: "LDAP", number: "1.0.0")
    create(:rubygem, :reindex, name: "LDAP-PLUS", number: "1.0.0")

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert_text "LDAP"
    assert_text "LDAP-PLUS"
  end

  test "searching for a yanked gem" do
    rubygem = create(:rubygem, name: "LDAP")
    create(:version, :reindex, rubygem: rubygem, indexed: false)

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert_text "No gems found"
    assert_text "YANKED (1)"

    click_link "Yanked (1)"

    assert_text "LDAP"
    assert page.has_selector? "a[href='#{rubygem_path('LDAP')}']"
  end

  test "searching for a gem with yanked versions" do
    rubygem = create(:rubygem, name: "LDAP")
    create(:version, :reindex, rubygem: rubygem, number: "1.1.1", indexed: true)
    create(:version, :reindex, rubygem: rubygem, number: "2.2.2", indexed: false)

    visit search_path

    fill_in "query", with: "LDAP"
    click_button "search_submit"

    assert_text("1.1.1")
    assert_no_text("2.2.2")
  end

  test "params has non white listed keys" do
    Kaminari.configure { |c| c.default_per_page = 1 }
    create(:rubygem, :reindex, name: "ruby-ruby", number: "1.0.0")
    create(:rubygem, :reindex, name: "ruby-gems", number: "1.0.0")

    visit "/search?query=ruby&original_script_name=javascript:alert(1)//&script_name=javascript:alert(1)//"

    assert_text "ruby-ruby"
    assert page.has_link?(href: "/search?page=2&query=ruby")
    Kaminari.configure { |c| c.default_per_page = 30 }
  end

  test "total result count more than (max pages x default per page) shows max pages and accurate total count" do
    silence_warnings do
      Kaminari.configure { |c| c.default_per_page = 1 }
      orignal_val = Gemcutter::SEARCH_MAX_PAGES
      Gemcutter::SEARCH_MAX_PAGES = 2

      create(:rubygem, :reindex, name: "ruby-ruby", number: "1.0.0")
      create(:rubygem, :reindex, name: "ruby-gems", number: "1.0.0")
      create(:rubygem, :reindex, name: "ruby-thing", number: "1.0.0")

      visit "/search?query=ruby"

      assert_text "3 gems"

      find(".last-page-button").click

      assert_current_path "/search?page=2&query=ruby"
      assert_text "3 gems"

      Gemcutter::SEARCH_MAX_PAGES = orignal_val
      Kaminari.configure { |c| c.default_per_page = 30 }
    end
  end

  test "filtering and sorting search results" do
    mit = create(:rubygem, name: "ruby-mit", downloads: 10)
    create(:version, rubygem: mit, licenses: ["MIT"])
    apache = create(:rubygem, name: "ruby-apache", downloads: 20)
    create(:version, rubygem: apache, licenses: ["Apache-2.0"])
    Rubygem.reindex

    visit "/search?query=ruby"

    assert_text "2 gems"

    # `check` re-reads the checkbox after clicking, but auto-submit has already replaced the page.
    find_field("Apache-2.0").click

    assert_current_path(/license%5B%5D=Apache-2.0/)
    assert_text "1 gem"
    assert_no_selector "[data-testid='rubygem-name']", text: "ruby-mit"

    within("[data-testid='active-filters']") { click_link "Apache-2.0" }

    assert_text "2 gems"

    select "Name A–Z", from: "Sort"

    # Turbo updates the URL before rendering; the selected attribute only exists in the new page.
    assert_selector "select[name=sort] option[value=name][selected]"
    assert_current_path(/sort=name/)
    assert_equal %w[ruby-apache ruby-mit], all("[data-testid='rubygem-name']").map(&:text)
  end

  test "searching for reverse dependencies" do
    dependency = create(:rubygem)
    create(:version, rubygem: dependency)

    gem = create(:rubygem)
    version_one = create(:version, rubygem: gem)
    create(:dependency, :runtime, version: version_one, rubygem: dependency)

    visit "/gems/#{dependency.name}/reverse_dependencies"

    assert_text "Search reverse dependencies Gems…"
    within "[data-testid='reverse-dependencies']" do
      assert_text gem.name
    end

    visit "/gems/#{gem.name}/reverse_dependencies"

    assert_no_text "Search reverse dependencies Gems…"
    assert_text "This gem has no reverse dependencies"
  end
end

# frozen_string_literal: true

require "test_helper"

class SearchesControllerTest < ActionController::TestCase
  include SearchKickHelper

  def create_web_gem(name, downloads:, updated:, licenses:)
    rubygem = create(:rubygem, name:, downloads:)
    create(:version, rubygem:, licenses:)
    rubygem.update_column(:updated_at, updated)
  end

  context "on GET to show with no search parameters" do
    setup { get :show }

    should respond_with :success

    should "see no results" do
      refute page.has_content?("Results")
    end
  end

  context "on GET to show with search parameters for a rubygem without versions" do
    setup do
      @sinatra = create(:rubygem, :reindex, name: "sinatra")

      assert_nil @sinatra.most_recent_version
      assert_predicate @sinatra.reload.versions.count, :zero?
      get :show, params: { query: "sinatra" }
    end

    should respond_with :success

    should "see no results" do
      refute page.has_content?("Results")
    end
  end

  context "on GET to show with search parameters" do
    setup do
      @sinatra = create(:rubygem, name: "sinatra")
      @sinatra_redux = create(:rubygem, name: "sinatra-redux")
      @brando = create(:rubygem, name: "brando")
      create(:version, :reindex, rubygem: @sinatra)
      create(:version, :reindex, rubygem: @sinatra_redux)
      create(:version, :reindex, rubygem: @brando)
      get :show, params: { query: "sinatra" }
    end

    should respond_with :success
    should "see sinatra on the page in the results" do
      assert page.has_content?(@sinatra.name)
      assert page.has_selector?("a[href='#{rubygem_path(@sinatra.slug)}']")
    end
    should "not see brando on the page in the results" do
      refute page.has_content?(@brando.name)
      refute page.has_selector?("a[href='#{rubygem_path(@brando.slug)}']")
    end
    should "display the number of gems" do
      assert page.has_content?("2 gems")
    end
  end

  context "on GET to show with search parameters and ES enabled" do
    setup do
      @sinatra = create(:rubygem, name: "sinatra")
      @sinatra_redux = create(:rubygem, name: "sinatra-redux")
      @brando = create(:rubygem, name: "brando")
      create(:version, :reindex, rubygem: @sinatra)
      create(:version, :reindex, rubygem: @sinatra_redux)
      create(:version, :reindex, rubygem: @brando)
      get :show, params: { query: "sinatra" }
    end

    should respond_with :success
    should "see sinatra on the page in the results" do
      assert_text @sinatra.name
      assert_selector "a[href='#{rubygem_path(@sinatra.slug)}']"
    end
    should "not see brando on the page in the results" do
      refute_text @brando.name
      refute_selector "a[href='#{rubygem_path(@brando.slug)}']"
    end
    should "display the number of gems" do
      assert page.has_text?("2 gems")
    end
    should "not see suggestions" do
      refute_text "Did you mean"
      refute_selector ".search-suggestions"
    end
  end

  context "on GET to show with filter and sort params" do
    setup do
      create_web_gem "web-alpha", downloads: 10, updated: 2.days.ago, licenses: ["MIT"]
      create_web_gem "web-beta", downloads: 30, updated: 8.days.ago, licenses: ["Apache-2.0"]
      create_web_gem "web-gamma", downloads: 20, updated: 1.day.ago, licenses: ["MIT"]
      Rubygem.reindex
    end

    should "show only matching gems in the selected order" do
      get :show, params: { query: "web", license: ["MIT"], updated: "week", sort: "downloads" }

      assert_response :success
      assert_equal %w[web-gamma web-alpha], page.all("[data-testid='rubygem-name']").map(&:text)
      assert_text "2 gems"
    end

    should "reflect the params in the form controls" do
      get :show, params: { query: "web", license: ["MIT"], updated: "week", sort: "downloads" }

      assert_selector "input[type=checkbox][name='license[]'][value='MIT'][checked]"
      refute_selector "input[type=checkbox][name='license[]'][value='Apache-2.0'][checked]"
      assert_selector "input[type=radio][name=updated][value=week][checked]"
      assert_selector "select[name=sort] option[value=downloads][selected]"
    end

    should "link each active filter chip to the same search without that filter" do
      get :show, params: { query: "web", license: ["MIT"], updated: "week", sort: "downloads" }

      chips = page.find("[data-testid='active-filters']")

      assert chips.has_link?("MIT", href: search_path(query: "web", sort: "downloads", updated: "week"))
      assert chips.has_link?("Past week", href: search_path(query: "web", sort: "downloads", license: ["MIT"]))
      assert chips.has_link?("Clear all filters", href: search_path(query: "web", sort: "downloads"))
    end

    should "show an empty state with a way out when filters match nothing" do
      get :show, params: { query: "web", license: ["Apache-2.0"], updated: "week" }

      assert_response :success
      refute_selector "[data-testid='search-result']"
      empty_state = page.find("[data-testid='search-empty']")

      assert empty_state.has_text?("No gems match this search with the current filters.")
      assert empty_state.has_link?("Clear all filters", href: search_path(query: "web"))
    end

    should "ignore unknown filter values" do
      get :show, params: { query: "web", sort: "_score", updated: "decade", license: { "x" => "MIT" } }

      assert_response :success
      assert_text "3 gems"
      refute_selector "[data-testid='active-filters']"
    end

    should "keep filters in pagination links" do
      Kaminari.configure { |c| c.default_per_page = 1 }
      get :show, params: { query: "web", license: ["MIT"], sort: "name" }

      assert page.has_link?(href: search_path(license: ["MIT"], page: 2, query: "web", sort: "name"))
    ensure
      Kaminari.configure { |c| c.default_per_page = 30 }
    end
  end

  context "on GET to show with non string search parameter" do
    setup do
      get :show, params: { query: { foo: "bar" } }
    end

    should respond_with :success

    should "see no results" do
      refute page.has_content?("Results")
    end
  end

  context "on GET to show with search parameters and no results" do
    setup do
      @sinatra = create(:rubygem, name: "sinatra")
      @sinatra_redux = create(:rubygem, name: "sinatra-redux")
      @brando = create(:rubygem, name: "brando")
      create(:version, :reindex, rubygem: @sinatra)
      create(:version, :reindex, rubygem: @sinatra_redux)
      create(:version, :reindex, rubygem: @brando)
      get :show, params: { query: "sinatre" }
    end

    should respond_with :success
    should "see sinatra on the page in the suggestions" do
      assert_text "Did you mean"
      assert_text @sinatra.name, page.find("[data-testid='search-suggestions']")
      assert_selector "a[href='#{search_path(query: @sinatra.name)}']"
    end
    should "not see sinatra on the page in the results" do
      refute_selector "a[href='#{rubygem_path(@sinatra.slug)}']"
    end
    should "not see brando on the page in the results" do
      refute_text @brando.name
      refute_selector "a[href='#{rubygem_path(@brando.slug)}']"
    end
    should "not see filters" do
      refute_text "Filter"
    end
  end

  context "on GET to show with search parameters with yanked gems" do
    setup do
      @sinatra = create(:rubygem, name: "sinatra")
      @sinatra_redux = create(:rubygem, name: "sinatra-redux")
      create(:version, :reindex, rubygem: @sinatra)
      create(:version, :reindex, :yanked, rubygem: @sinatra_redux)
      get :show, params: { query: @sinatra_redux.name.to_s, yanked: true }
    end

    should respond_with :success

    should "see sinatra_redux on the page in the results" do
      assert_selector "a[href='#{rubygem_path(@sinatra_redux.slug)}']"
    end
    should "not see sinatra on the page in the results" do
      refute_selector "a[href='#{rubygem_path(@sinatra.slug)}']"
    end
  end

  context "on GET to show with malformed query containing range syntax" do
    setup do
      get :show, params: { query: "aws-sdk AND updated:[2025-06-18 TO *}" }
    end

    should respond_with :success

    should "show error message" do
      assert page.has_content?("Invalid search query. Please simplify your search and try again.")
    end
  end

  context "on GET to show with query exceeding max length" do
    setup do
      get :show, params: { query: "a" * (SearchQuerySanitizer::MAX_QUERY_LENGTH + 1) }
    end

    should respond_with :success

    should "show error message" do
      assert page.has_content?("Invalid search query. Please simplify your search and try again.")
    end
  end

  context "on GET to show with valid advanced search query" do
    setup do
      @sinatra = create(:rubygem, name: "sinatra")
      create(:version, :reindex, rubygem: @sinatra, indexed: true)
      get :show, params: { query: "sinatra AND downloads:>0" }
    end

    should respond_with :success

    should "process the query successfully" do
      refute page.has_content?("Invalid search query. Please simplify your search and try again.")
    end
  end

  context "with elasticsearch down" do
    setup do
      @sinatra = create(:rubygem, name: "sinatra")
      @sinatra_redux = create(:rubygem, name: "sinatra-redux")
      create(:version, rubygem: @sinatra)
      create(:version, rubygem: @sinatra_redux)
    end
    should "error with friendly error message" do
      requires_toxiproxy
      toxiproxy_elasticsearch.down do
        get :show, params: { query: "sinatra" }

        assert_response :success
        assert page.has_content?("Search is currently unavailable. Please try again later.")
      end
    end
  end
end

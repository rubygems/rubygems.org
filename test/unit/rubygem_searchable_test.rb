require "test_helper"

class RubygemSearchableTest < ActiveSupport::TestCase
  include ESHelper

  setup do
    Rubygem.__elasticsearch__.create_index! force: true
  end

  context "#as_indexed_json" do
    setup do
      @rubygem = create(:rubygem, name: "example_gem", downloads: 10)
      create(:version, number: "1.0.0", rubygem: @rubygem)
      create(:version,
        number: "1.0.1",
        rubygem: @rubygem,
        summary: "some summary",
        description: "some description")
    end

    should "return a hash" do
      json = @rubygem.as_indexed_json
      assert_equal json.class, Hash
    end

    should "set values from most recent versions" do
      json = @rubygem.as_indexed_json

      expected_hash = {
        name:              "example_gem",
        downloads:         10,
        version:           "1.0.1",
        version_downloads: 0,
        platform:          "ruby",
        authors:           "Joe User",
        info:              "some description",
        licenses:          "MIT",
        metadata:          { "foo" => "bar" },
        sha:               "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78",
        project_uri:       "http://localhost/gems/example_gem",
        gem_uri:           "http://localhost/gems/example_gem-1.0.1.gem",
        homepage_uri:      "http://example.com",
        wiki_uri:          "http://example.com",
        documentation_uri: "http://example.com",
        mailing_list_uri:  "http://example.com",
        source_code_uri:   "http://example.com",
        bug_tracker_uri:   "http://example.com",
        yanked:            false,
        summary:           "some summary",
        description:       "some description",
        updated:           @rubygem.updated_at,
        dependencies:      { development: [], runtime: [] }
      }

      expected_hash.each do |k, v|
        assert_equal v, json[k]
      end
    end
  end

  context "rubygems analyzer" do
    setup do
      create(:rubygem, name: "example-gem", number: "0.0.1")
      create(:rubygem, name: "example_1", number: "0.0.1")
      create(:rubygem, name: "example.rb", number: "0.0.1")
      import_and_refresh
    end

    should "find all gems with matching tokens" do
      _, response = ElasticSearcher.new("example").search
      assert_equal 3, response.size
      results = %w[example-gem example_1 example.rb]
      assert_equal results, response.map(&:name)
    end
  end

  context "filter" do
    setup do
      example_1 = create(:rubygem, name: "example_1")
      example_2 = create(:rubygem, name: "example_2")
      create(:version, rubygem: example_1, indexed: false)
      create(:version, rubygem: example_2)
      import_and_refresh
    end

    should "filter yanked gems from the result" do
      _, response = ElasticSearcher.new("example").search
      assert_equal 1, response.size
      assert_equal "example_2", response.first.name
    end
  end

  context "multi_match" do
    setup do
      # without download, _score is calculated to 0.0
      example_gem1 = create(:rubygem, name: "keyword", downloads: 1)
      example_gem2 = create(:rubygem, name: "example_gem2", downloads: 1)
      example_gem3 = create(:rubygem, name: "example_gem3", downloads: 1)
      create(:version, rubygem: example_gem1, description: "some", summary: "some")
      create(:version, rubygem: example_gem2, description: "keyword", summary: "some")
      create(:version, rubygem: example_gem3, summary: "keyword", description: "some")
      import_and_refresh
    end

    should "look for keyword in name, summary and description and order them in same priority order" do
      _, response = ElasticSearcher.new("keyword").search
      names_order = %w[keyword example_gem3 example_gem2]
      assert_equal names_order, response.results.map(&:name)
    end
  end

  context "function_score" do
    setup do
      (10..30).step(10) do |downloads|
        rubygem = create(:rubygem, name: "gem_#{downloads}", downloads: downloads)
        create(:version, rubygem: rubygem)
      end
      import_and_refresh
    end

    should "boost score of result by downloads count" do
      _, response = ElasticSearcher.new("gem").search
      names_order = %w[gem_30 gem_20 gem_10]
      assert_equal names_order, response.results.map(&:name)
    end
  end

  context "source" do
    setup do
      rubygem = create(:rubygem, name: "example_gem", downloads: 10)
      create(:version, rubygem: rubygem, summary: "some summary", description: "some description")
      import_and_refresh
    end

    should "return all terms of source" do
      _, response = ElasticSearcher.new("example_gem").search
      hash = {
        name: "example_gem",
        downloads: 10,
        summary: "some summary",
        description: "some description"
      }

      hash.each do |k, v|
        assert_equal v, response.results.first._source[k]
      end
    end
  end

  context "suggest" do
    setup do
      example1 = create(:rubygem, name: "keyword")
      example2 = create(:rubygem, name: "keywordo")
      example3 = create(:rubygem, name: "keywo")
      [example1, example2, example3].each { |gem| create(:version, rubygem: gem) }
      import_and_refresh
    end

    should "suggest names of possible gems" do
      _, response = ElasticSearcher.new("keywor").search
      suggestions = %w[keyword keywo keywordo]
      assert_equal suggestions, response.suggestions.terms
    end
  end

  context "advanced search" do
    setup do
      rubygem1 = create(:rubygem, name: "example", downloads: 101)
      rubygem2 = create(:rubygem, name: "web-rubygem", downloads: 99)
      create(:version, rubygem: rubygem1, summary: "special word with web-rubygem")
      create(:version, rubygem: rubygem2, description: "example special word")
      import_and_refresh
    end

    should "filter gems on downloads" do
      _, response = ElasticSearcher.new("downloads:>100").search
      assert_equal 1, response.size
      assert_equal "example", response.first.name
    end

    should "filter gems on name" do
      _, response = ElasticSearcher.new("name:web-rubygem").search
      assert_equal 1, response.size
      assert_equal "web-rubygem", response.first.name
    end

    should "filter gems on summary" do
      _, response = ElasticSearcher.new("summary:special word").search
      assert_equal 1, response.size
      assert_equal "example", response.first.name
    end

    should "filter gems on description" do
      _, response = ElasticSearcher.new("description:example").search
      assert_equal 1, response.size
      assert_equal "web-rubygem", response.first.name
    end

    should "change default operator" do
      _, response = ElasticSearcher.new("example OR web-rubygem").search
      assert_equal 2, response.size
      assert_equal ["web-rubygem", "example"], response.map(&:name)
    end

    should "support wildcards" do
      _, response = ElasticSearcher.new("name:web*").search
      assert_equal 1, response.size
      assert_equal "web-rubygem", response.first.name
    end
  end

  context "aggregations" do
    setup do
      rubygem1 = create(:rubygem, name: "example")
      rubygem2 = create(:rubygem, name: "rubygem")
      create(:version, rubygem: rubygem1, summary: "gemest of all gems")
      create(:version, rubygem: rubygem2, description: "example gems set the example")
      rubygem1.update_column("updated_at", 2.days.ago)
      rubygem2.update_column("updated_at", 10.days.ago)
      import_and_refresh
      _, @response = ElasticSearcher.new("example").search
    end

    should "aggregate matched fields" do
      buckets = @response.response["aggregations"]["matched_field"]["buckets"]
      assert_equal 1, buckets["name"]["doc_count"]
      assert_equal 0, buckets["summary"]["doc_count"]
      assert_equal 1, buckets["description"]["doc_count"]
    end

    should "aggregate date range" do
      buckets = @response.response["aggregations"]["date_range"]["buckets"]
      assert_equal 2, buckets[0]["doc_count"]
      assert_equal 1, buckets[1]["doc_count"]
    end
  end

  context "#search" do
    context "exception handling" do
      setup { import_and_refresh }

      context "Elasticsearch::Transport::Transport::Errors::BadRequest" do
        setup do
          @ill_formated_query = "updated:[2016-08-10 TO }"
        end

        should "fallback to legacy search" do
          Rubygem.expects(:legacy_search).with(@ill_formated_query).returns(Rubygem.all)

          ElasticSearcher.new(@ill_formated_query).search
        end

        should "give correct error message" do
          expected_msg = "Failed to parse: '#{@ill_formated_query}'. Falling back to legacy search."

          @error_msg, = ElasticSearcher.new(@ill_formated_query).search

          assert_equal expected_msg, @error_msg
        end
      end

      context "Elasticsearch::Transport::Transport::Errors" do
        setup do
          Rubygem.expects(:legacy_search).with("something").returns(Rubygem.all)
        end

        should "fallback to legacy search and give correct error message" do
          requires_toxiproxy

          Toxiproxy[:elasticsearch].down do
            error_msg, = ElasticSearcher.new("something").search
            expected_msg = "Advanced search is currently unavailable. Falling back to legacy search."
            assert_equal expected_msg, error_msg
          end
        end
      end
    end

    context "query order" do
      setup do
        %w[rails-async async-rails].each do |gem_name|
          rubygem = create(:rubygem, name: gem_name, downloads: 10)
          create(:version, rubygem: rubygem)
        end
        import_and_refresh
      end

      should "not affect results" do
        _, response1 = ElasticSearcher.new("async rails").search
        _, response2 = ElasticSearcher.new("rails async").search
        assert_equal response1.results.map(&:name), response2.results.map(&:name)
      end
    end
  end
end

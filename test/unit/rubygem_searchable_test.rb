require 'test_helper'
include ESHelper

class RubygemSearchableTest < ActiveSupport::TestCase
  setup do
    Rubygem.__elasticsearch__.create_index! force: true
  end

  context '#as_indexed_json' do
    setup do
      @rubygem = create(:rubygem, name: "example_gem", downloads: 10)
      create(:version, number: '1.0.0', rubygem: @rubygem)
      create(:version,
        number: '1.0.1',
        rubygem: @rubygem,
        summary: 'some summary',
        description: 'some description')
    end

    should "return a hash" do
      json = @rubygem.as_indexed_json
      assert_equal json.class, Hash
    end

    should "set values from most recent versions" do
      json = @rubygem.as_indexed_json

      expected_hash = {
        name: 'example_gem',
        yanked: false,
        downloads: 10,
        summary: 'some summary',
        description: 'some description'
      }

      expected_hash.each do |k, v|
        assert_equal v, json[k]
      end
    end
  end

  context 'rubygems analyzer' do
    setup do
      create(:rubygem, name: 'example-gem', number: '0.0.1')
      create(:rubygem, name: 'example_1', number: '0.0.1')
      create(:rubygem, name: 'example.rb', number: '0.0.1')
      import_and_refresh
    end

    should 'find all gems with matching tokens' do
      response = Rubygem.elastic_search "example"
      assert_equal 3, response.results.size
      results = %w[example-gem example_1 example.rb]
      assert_equal results, response.results.map(&:name)
    end
  end

  context 'filter' do
    setup do
      example_1 = create(:rubygem, name: "example_1")
      example_2 = create(:rubygem, name: "example_2")
      create(:version, rubygem: example_1, indexed: false)
      create(:version, rubygem: example_2)
      import_and_refresh
    end

    should "filter yanked gems from the result" do
      response = Rubygem.elastic_search "example"
      assert_equal 1, response.results.size
      assert_equal "example_2", response.results.first.name
    end
  end

  context 'multi_match' do
    setup do
      # without download, _score is calculated to 0.0
      example_gem1 = create(:rubygem, name: "keyword", downloads: 1)
      example_gem2 = create(:rubygem, name: "example_gem2", downloads: 1)
      example_gem3 = create(:rubygem, name: "example_gem3", downloads: 1)
      create(:version, rubygem: example_gem1, description: 'some', summary: 'some')
      create(:version, rubygem: example_gem2, description: 'keyword', summary: 'some')
      create(:version, rubygem: example_gem3, summary: 'keyword', description: 'some')
      import_and_refresh
    end

    should "look for keyword in name, summary and description and order them in same priority order" do
      response = Rubygem.elastic_search "keyword"
      names_order = %w[keyword example_gem3 example_gem2]
      assert_equal names_order, response.results.map(&:name)
    end
  end

  context 'function_score' do
    setup do
      (10..30).step(10) do |downloads|
        rubygem = create(:rubygem, name: "gem_#{downloads}", downloads: downloads)
        create(:version, rubygem: rubygem)
      end
      import_and_refresh
    end

    should "boost score of result by downloads count" do
      response = Rubygem.elastic_search "gem"
      names_order = %w[gem_30 gem_20 gem_10]
      assert_equal names_order, response.results.map(&:name)
    end
  end

  context 'source' do
    setup do
      rubygem = create(:rubygem, name: "example_gem", downloads: 10)
      create(:version, rubygem: rubygem, summary: 'some summary', description: 'some description')
      import_and_refresh
    end

    should "return all terms of source" do
      response = Rubygem.elastic_search "example_gem"
      hash = {
        name: 'example_gem',
        downloads: 10,
        summary: 'some summary',
        description: 'some description'
      }

      hash.each do |k, v|
        assert_equal v, response.results.first._source[k]
      end
    end
  end

  context 'suggest' do
    setup do
      example1 = create(:rubygem, name: 'keyword')
      example2 = create(:rubygem, name: 'keywordo')
      example3 = create(:rubygem, name: 'keywo')
      [example1, example2, example3].each { |gem| create(:version, rubygem: gem) }
      import_and_refresh
    end

    should "suggest names of possible gems" do
      response = Rubygem.elastic_search "keywor"
      suggestions = %w[keyword keywo keywordo]
      assert_equal suggestions, response.suggestions.terms
    end
  end

  context 'advanced search' do
    setup do
      rubygem1 = create(:rubygem, name: 'example', downloads: 101)
      rubygem2 = create(:rubygem, name: 'web-rubygem', downloads: 99)
      create(:version, rubygem: rubygem1, summary: 'special word with web-rubygem')
      create(:version, rubygem: rubygem2, description: 'example special word')
      import_and_refresh
    end

    should "filter gems on downloads" do
      response = Rubygem.elastic_search "downloads:>100"
      assert_equal 1, response.results.size
      assert_equal "example", response.results.first.name
    end

    should "filter gems on name" do
      response = Rubygem.elastic_search "name:web-rubygem"
      assert_equal 1, response.results.size
      assert_equal "web-rubygem", response.results.first.name
    end

    should "filter gems on summary" do
      response = Rubygem.elastic_search "summary:special word"
      assert_equal 1, response.results.size
      assert_equal "example", response.results.first.name
    end

    should "filter gems on description" do
      response = Rubygem.elastic_search "description:example"
      assert_equal 1, response.results.size
      assert_equal "web-rubygem", response.results.first.name
    end

    should "change default operator" do
      response = Rubygem.elastic_search "example OR web-rubygem"
      assert_equal 2, response.results.size
      assert_equal ["web-rubygem", "example"], response.results.map(&:name)
    end

    should "support wildcards" do
      response = Rubygem.elastic_search "name:web*"
      assert_equal 1, response.results.size
      assert_equal "web-rubygem", response.results.first.name
    end
  end

  context 'aggregations' do
    setup do
      rubygem1 = create(:rubygem, name: 'example')
      rubygem2 = create(:rubygem, name: 'rubygem')
      create(:version, rubygem: rubygem1, summary: 'gemest of all gems')
      create(:version, rubygem: rubygem2, description: 'example gems set the example')
      rubygem1.update_column('updated_at', 2.days.ago)
      rubygem2.update_column('updated_at', 10.days.ago)
      import_and_refresh
      @response = Rubygem.elastic_search "example"
    end

    should "aggregate matched fields" do
      buckets = @response.response['aggregations']['matched_field']['buckets']
      assert_equal 1, buckets['name']['doc_count']
      assert_equal 0, buckets['summary']['doc_count']
      assert_equal 1, buckets['description']['doc_count']
    end

    should "aggregate date range" do
      buckets = @response.response['aggregations']['date_range']['buckets']
      assert_equal 2, buckets[0]['doc_count']
      assert_equal 1, buckets[1]['doc_count']
    end
  end

  context "#search" do
    context "exception handling" do
      setup { import_and_refresh }

      context "Elasticsearch::Transport::Transport::Errors::BadRequest" do
        setup do
          @ill_formated_query = "updated:[2016-08-10 TO }"
          Rubygem.stubs(:legacy_search).returns Rubygem.all
          @error_msg, = Rubygem.search(@ill_formated_query, es: true)
        end

        should "fallback to legacy search" do
          assert_received(Rubygem, :legacy_search) { |arg| arg.with(@ill_formated_query) }
        end

        should "give correct error message" do
          expected_msg = "Failed to parse: '#{@ill_formated_query}'. Falling back to legacy search."
          assert_equal expected_msg, @error_msg
        end
      end

      context "Elasticsearch::Transport::Transport::Errors" do
        should "fallback to legacy search and give correct error message" do
          requires_toxiproxy
          Rubygem.stubs(:legacy_search).returns Rubygem.all

          Toxiproxy[:elasticsearch].down do
            error_msg, = Rubygem.search("something", es: true)
            expected_msg = "Advanced search is currently unavailable. Falling back to legacy search."
            assert_equal expected_msg, error_msg
            assert_received(Rubygem, :legacy_search) { |arg| arg.with("something") }
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
        response1 = Rubygem.elastic_search "async rails"
        response2 = Rubygem.elastic_search "rails async"
        assert_equal response1.results.map(&:name), response2.results.map(&:name)
      end
    end
  end
end

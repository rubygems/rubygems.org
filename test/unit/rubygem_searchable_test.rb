require 'test_helper'

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

  def import_and_refresh
    Rubygem.import
    Rubygem.__elasticsearch__.refresh_index!
    # wait for indexing to finish
    Rubygem.__elasticsearch__.client.cluster.health wait_for_status: 'yellow'
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
      create(:version, rubygem: example_gem1)
      create(:version, rubygem: example_gem2, description: 'some text and keyword')
      create(:version, rubygem: example_gem3, summary: 'some keyword')
      import_and_refresh
    end

    should "look for keyword in name, summary and description and order them in same priority order" do
      response = Rubygem.elastic_search "keyword"
      names_order = %w(keyword example_gem3 example_gem2)
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
      names_order = %w(gem_30 gem_20 gem_10)
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
      suggestions = %w(keyword keywo keywordo)
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
end

# frozen_string_literal: true

require "test_helper"

class DatabaseSearcherTest < ActiveSupport::TestCase
  def gem!(name, downloads: 0, summary: nil)
    rubygem = create(:rubygem, name:, downloads:)
    create(:version, rubygem:, number: "1.0.0", summary:)
    RubygemSearchSummary.refresh!(rubygem)
    rubygem
  end

  def names(query, page: 1)
    error, gems = DatabaseSearcher.new(query, page:).search

    assert_nil error
    gems.map(&:name)
  end

  context ".plain_query?" do
    should "accept gem-name-like text" do
      assert DatabaseSearcher.plain_query?("rails")
      assert DatabaseSearcher.plain_query?("rails html")
      assert DatabaseSearcher.plain_query?("rails-html_sanitizer.rb")
      assert DatabaseSearcher.plain_query?("  Rails  ")
    end

    should "reject advanced query syntax" do
      refute DatabaseSearcher.plain_query?("name: rails")
      refute DatabaseSearcher.plain_query?("downloads:>100")
      refute DatabaseSearcher.plain_query?("rails OR sinatra")
      refute DatabaseSearcher.plain_query?("rails AND downloads:>0")
      refute DatabaseSearcher.plain_query?("rails*")
      refute DatabaseSearcher.plain_query?('"rails html"')
      refute DatabaseSearcher.plain_query?("-rails")
      refute DatabaseSearcher.plain_query?("")
    end
  end

  context ".use_for?" do
    should "use the database only when the flag is on and the query is plain text" do
      refute DatabaseSearcher.use_for?("rails")

      with_feature(FeatureFlag::DB_SEARCH) do
        assert DatabaseSearcher.use_for?("rails")
        refute DatabaseSearcher.use_for?("name: rails")
      end
    end
  end

  context "#search" do
    should "rank an exact name match above more-downloaded partial matches" do
      gem!("rails-html-sanitizer", downloads: 900_000)
      gem!("rails", downloads: 1_000)

      assert_equal %w[rails rails-html-sanitizer], names("rails")
    end

    should "let a far more downloaded partial match outrank an obscure exact match" do
      gem!("sinatra", downloads: 10)
      gem!("sinatra-redux", downloads: 5_000)

      assert_equal %w[sinatra-redux sinatra], names("sinatra")
    end

    should "order similar matches by downloads" do
      gem!("rack-foo", downloads: 10)
      gem!("rack-bar", downloads: 5_000)

      assert_equal %w[rack-bar rack-foo], names("rack")
    end

    should "match the start of any name segment, but not the middle of a word" do
      gem!("async-http")
      gem!("falcon_async")
      gem!("carinariasyncytium")

      assert_equal %w[async-http falcon_async].sort, names("async").sort
    end

    should "treat spaces and separators in the query as interchangeable" do
      gem!("rails-html-sanitizer")
      gem!("rails_html")
      gem!("rails-dom-testing")

      assert_equal %w[rails-html-sanitizer rails_html].sort, names("rails html").sort
      assert_equal %w[rails-html-sanitizer rails_html].sort, names("rails-html").sort
    end

    should "be case insensitive" do
      gem!("Nokogiri")

      assert_equal %w[Nokogiri], names("NOKOGIRI")
    end

    should "exclude gems without indexed versions" do
      gem!("sinatra")
      yanked = gem!("sinatra-yanked")
      yanked.versions.each { |v| v.update!(indexed: false) }
      create(:rubygem, name: "sinatra-empty")

      assert_equal %w[sinatra], names("sinatra")
    end

    should "match two-character queries as a name prefix only" do
      gem!("pg")
      gem!("pg_search")
      gem!("upgrade")

      assert_equal %w[pg pg_search].sort, names("pg").sort
    end

    should "match single-character queries exactly" do
      gem!("a")
      gem!("ab")

      assert_equal %w[a], names("a")
    end

    should "not treat LIKE wildcards in the query as wildcards" do
      gem!("ab")

      assert_empty names("a_")
      assert_empty names("a%")
    end

    should "paginate" do
      31.times { |i| gem!("paged-#{i}") }

      error, gems = DatabaseSearcher.new("paged", page: 2).search

      assert_nil error
      assert_equal 31, gems.total_count
      assert_equal 1, gems.size
    end

    should "return a friendly error when the query fails" do
      Rubygem.stubs(:with_versions).raises(ActiveRecord::StatementInvalid, "boom")

      error, gems = DatabaseSearcher.new("rails").search

      assert_equal "Search is currently unavailable. Please try again later.", error
      assert_nil gems
    end
  end

  context "#suggestions" do
    should "return gems starting with the query, most downloaded first" do
      gem!("rspec-core", downloads: 100)
      gem!("rspec", downloads: 50)
      gem!("rspec-rails", downloads: 500)
      gem!("minitest-rspec", downloads: 1_000)

      assert_equal %w[rspec-rails rspec-core rspec], DatabaseSearcher.new("rspec").suggestions
    end

    should "exclude gems without indexed versions" do
      gem!("sidekiq")
      create(:rubygem, name: "sidekiq-empty")

      assert_equal %w[sidekiq], DatabaseSearcher.new("sid").suggestions
    end

    should "limit results" do
      (DatabaseSearcher::SUGGESTIONS_LIMIT + 1).times { |i| gem!("many-#{i}") }

      assert_equal DatabaseSearcher::SUGGESTIONS_LIMIT, DatabaseSearcher.new("many").suggestions.size
    end
  end

  context "#search with summaries" do
    should "find gems whose summary matches, using English stemming" do
      gem!("devise", summary: "Flexible authentication solution for Rails")
      gem!("sinatra", summary: "Classy web development")

      assert_equal %w[devise], names("authenticating")
    end

    should "require every query word to appear in the summary" do
      gem!("devise", summary: "Flexible authentication solution for Rails")
      gem!("omniauth", summary: "A generalized Rack framework for multiple-provider authentication")

      assert_equal %w[devise], names("rails authentication")
    end

    should "rank a name match above a summary-only match of similar popularity" do
      gem!("warden-strategies", summary: "Rack authentication strategies", downloads: 1_000)
      gem!("authentication-kit", downloads: 1_000)

      assert_equal %w[authentication-kit warden-strategies], names("authentication")
    end

    should "give a gem matching on both name and summary a bonus" do
      # rack-cors would win on name similarity and alphabetical order alone
      gem!("rack-cors", downloads: 1_000)
      gem!("rack-timeout", summary: "Rack middleware which aborts requests", downloads: 1_000)

      assert_equal %w[rack-timeout rack-cors], names("rack")
    end

    should "not search summaries for short queries" do
      gem!("pg", summary: "Pg is the Ruby interface to PostgreSQL")
      gem!("sequel", summary: "The Database Toolkit for Ruby, with pg support")

      assert_equal %w[pg], names("pg")
    end

    should "exclude summary matches for gems without indexed versions" do
      gem!("devise", summary: "Flexible authentication solution for Rails")
      yanked = gem!("devise-yanked", summary: "Authentication, yanked")
      yanked.versions.each { |v| v.update!(indexed: false) }

      assert_equal %w[devise], names("authentication")
    end

    should "only consider the most downloaded summary matches" do
      gem!("popular", summary: "An authentication library", downloads: 1_000)
      gem!("obscure", summary: "Another authentication library", downloads: 1)
      DatabaseSearcher.any_instance.stubs(:summary_candidate_limit).returns(1)

      assert_equal %w[popular], names("authentication")
    end
  end
end

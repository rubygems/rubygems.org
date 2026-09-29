# frozen_string_literal: true

require "test_helper"

class SearchComparisonLoggerTest < ActiveSupport::TestCase
  include SearchKickHelper

  setup do
    @output = StringIO.new
    @original_logger = SearchComparisonLogger.instance_variable_get(:@logger)
    SearchComparisonLogger.logger = ActiveSupport::Logger.new(@output).tap { |l| l.formatter = ->(*, msg) { "#{msg}\n" } }
    Rails.configuration.x.search_comparison_log = true

    create(:rubygem, :reindex, name: "sinatra", number: "1.0.0", downloads: 100)
    create(:rubygem, name: "sinatra-db-only", number: "1.0.0", downloads: 50)
    Rubygem.searchkick_index.refresh
  end

  teardown do
    Rails.configuration.x.search_comparison_log = nil
    SearchComparisonLogger.logger = @original_logger
  end

  should "log both engines' results side by side" do
    SearchComparisonLogger.log_search("sinatra", page: 1, served_by: "DatabaseSearcher")
    log = @output.string

    assert_match(/search "sinatra" page=1 served_by=DatabaseSearcher/, log)
    assert_match(/^\s+total\s+2\s+1$/, log)
    assert_match(/^\s+1\s+sinatra\s+sinatra$/, log)
    assert_match(/^\s+2\s+sinatra-db-only\s*$/, log)
    assert_match(/only database: sinatra-db-only/, log)
  end

  should "log both engines' autocomplete suggestions" do
    SearchComparisonLogger.log_suggestions("sin", served_by: "ElasticSearcher")
    log = @output.string

    assert_match(/autocomplete "sin" served_by=ElasticSearcher/, log)
    assert_match(/^\s+1\s+sinatra\s+sinatra$/, log)
  end

  should "skip advanced queries, which only OpenSearch can answer" do
    SearchComparisonLogger.log_search("name: sinatra", page: 1, served_by: "ElasticSearcher")

    assert_empty @output.string
  end

  should "do nothing when disabled" do
    Rails.configuration.x.search_comparison_log = nil
    DatabaseSearcher.expects(:new).never

    SearchComparisonLogger.log_search("sinatra", page: 1, served_by: "ElasticSearcher")

    assert_empty @output.string
  end

  should "log failures instead of raising" do
    DatabaseSearcher.stubs(:new).raises(RuntimeError, "boom")

    SearchComparisonLogger.log_search("sinatra", page: 1, served_by: "ElasticSearcher")

    assert_match(/search comparison failed for "sinatra": RuntimeError: boom/, @output.string)
  end
end

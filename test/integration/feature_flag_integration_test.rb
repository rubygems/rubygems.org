require "test_helper"

class FeatureFlagIntegrationTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @service = FakeSearchService.new(@user)

    # Clean up all feature flags before each test
    Flipper.features.each(&:remove)
  end

  def teardown
    # Clean up after each test
    Flipper.features.each(&:remove)
  end

  # Example class that uses feature flags to vary behavior
  class FakeSearchService
    def initialize(user = nil)
      @user = user
    end

    def search(query)
      if FeatureFlag.enabled?(:new_search_algorithm, @user)
        enhanced_search(query)
      else
        legacy_search(query)
      end
    end

    def results_per_page
      if FeatureFlag.enabled?(:increased_page_size, @user)
        50
      else
        25
      end
    end

    def show_advanced_filters?
      FeatureFlag.enabled?(:advanced_search_filters, @user)
    end

    private

    def enhanced_search(query)
      {
        algorithm: "enhanced",
        query: query,
        results: %w[enhanced_result_1 enhanced_result_2]
      }
    end

    def legacy_search(query)
      {
        algorithm: "legacy",
        query: query,
        results: %w[legacy_result_1 legacy_result_2]
      }
    end
  end

  test "search service uses legacy algorithm when feature disabled" do
    results = @service.search("rails")

    assert_equal "legacy", results[:algorithm]
    assert_equal %w[legacy_result_1 legacy_result_2], results[:results]
  end

  test "search service uses enhanced algorithm when feature enabled globally" do
    FeatureFlag.enable_globally(:new_search_algorithm)

    results = @service.search("rails")

    assert_equal "enhanced", results[:algorithm]
    assert_equal %w[enhanced_result_1 enhanced_result_2], results[:results]
  end

  test "search service uses enhanced algorithm for specific actor" do
    beta_user = create(:user)
    regular_user = create(:user)

    FeatureFlag.enable_for_actor(:new_search_algorithm, beta_user)

    beta_service = FakeSearchService.new(beta_user)
    regular_service = FakeSearchService.new(regular_user)

    beta_results = beta_service.search("rails")
    regular_results = regular_service.search("rails")

    assert_equal "enhanced", beta_results[:algorithm]
    assert_equal "legacy", regular_results[:algorithm]
  end

  test "page size changes based on feature flag" do
    # Default page size
    assert_equal 25, @service.results_per_page

    # Enable increased page size
    FeatureFlag.enable_for_actor(:increased_page_size, @user)

    assert_equal 50, @service.results_per_page

    # Disable for this actor
    FeatureFlag.disable_for_actor(:increased_page_size, @user)

    assert_equal 25, @service.results_per_page
  end

  test "advanced filters visibility controlled by feature flag" do
    # Filters hidden by default
    refute_predicate @service, :show_advanced_filters?

    # Enable for specific user
    FeatureFlag.enable_for_actor(:advanced_search_filters, @user)

    assert_predicate @service, :show_advanced_filters?

    # Test with different user (should still be hidden)
    other_user = create(:user)
    other_service = FakeSearchService.new(other_user)

    refute_predicate other_service, :show_advanced_filters?
  end

  test "percentage rollout affects multiple users differently" do
    users_list = create_list(:user, 2)

    # Enable for 100% of users
    FeatureFlag.enable_percentage(:new_search_algorithm, 100)

    users_list.each do |user|
      service = FakeSearchService.new(user)
      results = service.search("rails")

      assert_equal "enhanced", results[:algorithm]
    end

    # Disable for all users
    FeatureFlag.enable_percentage(:new_search_algorithm, 0)

    users_list.each do |user|
      service = FakeSearchService.new(user)
      results = service.search("rails")

      assert_equal "legacy", results[:algorithm]
    end
  end

  test "service works without user (anonymous usage)" do
    service = FakeSearchService.new(nil)

    # Should use legacy by default
    results = service.search("rails")

    assert_equal "legacy", results[:algorithm]

    # Enable globally - should affect anonymous users too
    FeatureFlag.enable_globally(:new_search_algorithm)

    results = service.search("rails")

    assert_equal "enhanced", results[:algorithm]
  end

  test "multiple feature flags can be active simultaneously" do
    FeatureFlag.enable_for_actor(:new_search_algorithm, @user)
    FeatureFlag.enable_for_actor(:increased_page_size, @user)
    FeatureFlag.enable_for_actor(:advanced_search_filters, @user)

    # All features should be active
    results = @service.search("rails")

    assert_equal "enhanced", results[:algorithm]
    assert_equal 50, @service.results_per_page
    assert_predicate @service, :show_advanced_filters?

    # Disable one feature
    FeatureFlag.disable_for_actor(:increased_page_size, @user)

    # Other features should remain active
    results = @service.search("rails")

    assert_equal "enhanced", results[:algorithm]
    assert_equal 25, @service.results_per_page # Back to default
    assert_predicate @service, :show_advanced_filters?
  end

  test "disabling globally overrides actor-specific enablement" do
    # Enable for specific actor
    FeatureFlag.enable_for_actor(:new_search_algorithm, @user)

    results = @service.search("rails")

    assert_equal "enhanced", results[:algorithm]

    # Disable globally (this removes all enablements)
    FeatureFlag.disable_globally(:new_search_algorithm)

    results = @service.search("rails")

    assert_equal "legacy", results[:algorithm]
  end
end

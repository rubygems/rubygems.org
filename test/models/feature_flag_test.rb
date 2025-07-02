require "test_helper"

class FeatureFlagTest < ActiveSupport::TestCase
  def setup
    @allowed = create(:user)
    @blocked = create(:user)

    Flipper.features.each(&:remove)
  end

  def teardown
    Flipper.features.each(&:remove)
  end

  test "enabled? returns false for non-existent flag" do
    refute FeatureFlag.enabled?(:non_existent_flag)
  end

  test "enabled? returns true for globally enabled flag" do
    FeatureFlag.enable_globally(:global_flag)

    assert FeatureFlag.enabled?(:global_flag)
  end

  test "enabled? returns true when the feature is enabled for the given actor" do
    FeatureFlag.enable_for_actor(:global_flag, @allowed)

    refute FeatureFlag.enabled?(:global_flag)
    assert FeatureFlag.enabled?(:global_flag, @allowed)
  end

  test "enabled? returns false for globally disabled flag" do
    FeatureFlag.enable_globally(:test_flag)
    FeatureFlag.disable_globally(:test_flag)

    refute FeatureFlag.enabled?(:test_flag)
  end

  test "enabled? returns false when the feature is not enabled for the given actor" do
    FeatureFlag.enable_for_actor(:global_flag, @allowed)
    FeatureFlag.disable_for_actor(:global_flag, @blocked)

    assert FeatureFlag.enabled?(:global_flag, @allowed)
    refute FeatureFlag.enabled?(:global_flag, @blocked)
  end

  test "enable_for_actor enables flag for specific actor" do
    FeatureFlag.enable_for_actor(:actor_flag, @allowed)

    assert FeatureFlag.enabled?(:actor_flag, @allowed)
    refute FeatureFlag.enabled?(:actor_flag, @blocked)
  end

  test "enable_percentage enables flag for percentage of actors" do
    FeatureFlag.enable_percentage(:percentage_flag, 100)

    assert FeatureFlag.enabled?(:percentage_flag, @allowed)

    FeatureFlag.enable_percentage(:percentage_flag, 0)

    refute FeatureFlag.enabled?(:percentage_flag, @allowed)
  end

  test "disable_globally removes all enablements for flag" do
    FeatureFlag.enable_globally(:disable_test)
    FeatureFlag.enable_for_actor(:disable_test, @allowed)

    FeatureFlag.disable_globally(:disable_test)

    refute FeatureFlag.enabled?(:disable_test)
    refute FeatureFlag.enabled?(:disable_test, @allowed)
  end
end

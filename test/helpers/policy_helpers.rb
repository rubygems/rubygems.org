module PolicyHelpers
  extend ActiveSupport::Concern

  def assert_authorized(policy_or_actor, action)
    policy = policy_or_actor if policy_or_actor.is_a?(ApplicationPolicy)
    policy ||= policy!(policy_or_actor)

    assert_predicate policy, action
    assert_nil policy.error
  end

  def refute_authorized(policy_or_actor, action, message = nil)
    policy = policy_or_actor if policy_or_actor.is_a?(ApplicationPolicy)
    policy ||= policy!(policy_or_actor)

    refute_predicate policy, action
    assert_equal message.chomp, policy.error&.chomp if message
  end
end

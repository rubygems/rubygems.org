module PolicyHelpers
  extend ActiveSupport::Concern

  def assert_authorized(policy_or_actor, action)
    policy = policy_or_actor if policy_or_actor.is_a?(ApplicationPolicy)
    policy ||= policy!(policy_or_actor)

    result = policy.send(action)
    flunk "Expected #{policy.class} to authorize #{action.inspect}\n#{pretty_print_policy(policy)}" unless result
    flunk "Expected #{policy.class}##{action} not to produce an error: #{policy.error}\n#{pretty_print_policy(policy)}" if policy.error

    assert result
  end

  def refute_authorized(policy_or_actor, action, message = nil)
    policy = policy_or_actor if policy_or_actor.is_a?(ApplicationPolicy)
    policy ||= policy!(policy_or_actor)

    result = policy.send(action)
    flunk "Expected #{policy.class} to deny #{action.inspect}\n#{pretty_print_policy(policy)}" if result
    assert_equal message.chomp, policy.error&.chomp if message

    refute result
  end

  def pretty_print_policy(policy)
    user = policy.user.respond_to?(:handle) ? "#<User id: #{policy.user.id}, handle: #{policy.user.handle.inspect}>" : policy.user.inspect
    error = policy.error ? "  Error: #{policy.error}\n" : nil
    "#{error}  User: #{user}\n  Record: #{policy.record.inspect}"
  end
end

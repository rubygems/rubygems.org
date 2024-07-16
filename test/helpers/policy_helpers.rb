module PolicyHelpers
  extend ActiveSupport::Concern

  def assert_authorized(actor, action)
    policy = policy!(actor)

    assert_predicate policy, action
    assert_nil policy.error
  end

  def refute_authorized(actor, action, message = nil)
    policy = policy!(actor)

    refute_predicate policy, action
    assert_equal message.chomp, policy.error&.chomp if message
  end
end

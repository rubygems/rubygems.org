# frozen_string_literal: true

require "test_helper"

class OIDC::AccessPolicyTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  should validate_presence_of :statements

  setup do
    @role = build(:oidc_api_key_role)
  end

  test "validates policy complexity limits" do
    assert_predicate access_policy_with_conditions([2, 2, 2, 2, 2]), :valid?

    too_many_statements = access_policy_with_conditions([1, 1, 1, 1, 1, 1])
    too_many_conditions = access_policy_with_conditions([11])

    refute_predicate too_many_statements, :valid?
    refute_predicate too_many_conditions, :valid?
    expected_error = ["must contain at most 5 statements and 10 conditions in total"]

    assert_equal expected_error, too_many_statements.errors.messages[:statements]
    assert_equal expected_error, too_many_conditions.errors.messages[:statements]
  end

  context "#verify_access!" do
    should "allow a policy at the complexity limits" do
      policy = access_policy_with_conditions([2, 2, 2, 2, 2])

      assert_nil policy.verify_access!(JSON::JWT.new(iss: "iss", c: "value"))
    end

    should "reject a legacy policy over the complexity limits" do
      policy = access_policy_with_conditions([11])

      error = assert_raises(OIDC::AccessPolicy::AccessError) do
        policy.verify_access!(JSON::JWT.new(iss: "iss", c: "value"))
      end

      assert_equal "denying due to policy exceeding complexity limits", error.message
    end

    context "with an unknown effect on matching statement" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "unknown",
          principal: { oidc: "iss" },
          conditions: []
                                                ])
      end

      should "raise error" do
        jwt = JSON::JWT.new({ iss: "iss" })
        assert_raise("Unhandled effect unknown") { @access_policy.verify_access!(jwt) }
      end

      should "fail to validate" do
        @access_policy.validate

        assert_equal ["is not included in the list"], @access_policy.errors.messages[:"statements[0].effect"]
      end
    end

    context "with an explicit deny" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "deny",
          principal: { oidc: "iss" },
          conditions: []
                                                ])
      end

      should "raise AccessError" do
        jwt = JSON::JWT.new({ iss: "iss" })
        assert_raise(OIDC::AccessPolicy::AccessError) { @access_policy.verify_access!(jwt) }
      end
    end

    context "with no statements" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [])
      end

      should "raise AccessError" do
        jwt = JSON::JWT.new({ iss: "iss" })
        assert_raise(OIDC::AccessPolicy::AccessError) { @access_policy.verify_access!(jwt) }
      end
    end

    context "with string_equals condition" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [
            operator: "string_equals",
            claim: "c",
            value: "value"
          ]
                                                ])
      end

      should "raise AccessError when unequal" do
        jwt = JSON::JWT.new({ iss: "iss", c: "not_value" })
        assert_raise(OIDC::AccessPolicy::AccessError) { @access_policy.verify_access!(jwt) }
      end

      should "return nil when equal" do
        jwt = JSON::JWT.new({ iss: "iss", c: "value" })

        assert_nil @access_policy.verify_access!(jwt)
      end
    end

    context "with string_matches condition" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [
            operator: "string_matches",
            claim: "c",
            value: "\\A[v].{3}e.*"
          ]
                                                ])
      end

      should "raise AccessError when no match" do
        jwt = JSON::JWT.new({ iss: "iss", c: "not_value" })
        assert_raise(OIDC::AccessPolicy::AccessError) { @access_policy.verify_access!(jwt) }
      end

      should "return nil when matches" do
        jwt = JSON::JWT.new({ iss: "iss", c: "value" })

        assert_nil @access_policy.verify_access!(jwt)
      end
    end

    context "with a string_matches condition matched against a longer claim" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [
            operator: "string_matches",
            claim: "c",
            value: "one/two.*"
          ]
                                                ])
      end

      should "return nil when the pattern describes the whole claim" do
        assert_nil @access_policy.verify_access!(JSON::JWT.new({ iss: "iss", c: "one/two/three" }))
      end

      should "raise AccessError when the claim only contains the pattern" do
        assert_raise(OIDC::AccessPolicy::AccessError) do
          @access_policy.verify_access!(JSON::JWT.new({ iss: "iss", c: "zero/one/two/three" }))
        end
      end
    end

    context "with a string_matches condition that alternates" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [
            operator: "string_matches",
            claim: "c",
            value: "one|two"
          ]
                                                ])
      end

      should "return nil for either alternative in full" do
        assert_nil @access_policy.verify_access!(JSON::JWT.new({ iss: "iss", c: "one" }))
        assert_nil @access_policy.verify_access!(JSON::JWT.new({ iss: "iss", c: "two" }))
      end

      should "raise AccessError when an alternative is only a prefix or a suffix" do
        assert_raise(OIDC::AccessPolicy::AccessError) { @access_policy.verify_access!(JSON::JWT.new({ iss: "iss", c: "one!" })) }
        assert_raise(OIDC::AccessPolicy::AccessError) { @access_policy.verify_access!(JSON::JWT.new({ iss: "iss", c: "!two" })) }
      end
    end

    context "with a string_matches condition that does not compile" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [
            operator: "string_matches",
            claim: "sub",
            value: "repo:fakeuser/["
          ]
                                                ])
      end

      should "fail to validate rather than save and raise when a token is exchanged" do
        @access_policy.validate

        assert_equal ["is not a valid regular expression: premature end of char-class: /repo:fakeuser\\/[/"],
          @access_policy.errors.messages[:"statements[0].conditions[0].value"]
      end

      should "reject patterns that escape the whole-claim anchors" do
        @access_policy.statements.sole.conditions.sole.value = "foo)|(?:bar"

        refute_predicate @access_policy, :valid?

        %w[fooXYZ evil/bar].each do |claim|
          assert_raise(RegexpError) do
            @access_policy.verify_access!(JSON::JWT.new(iss: "iss", sub: claim))
          end
        end
      end
    end

    context "with a string_matches condition against a claim that is not a string" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [
            operator: "string_matches",
            claim: "iat",
            value: ".*"
          ]
                                                ])
      end

      should "validate, since the claim is only known once a token is exchanged" do
        assert_predicate @access_policy, :valid?
      end

      # Regexp#match? raises TypeError on anything but a string.
      should "raise AccessError for a numeric claim" do
        jwt = JSON::JWT.new({ iss: "iss", iat: 1_760_000_000 })

        assert_raise(OIDC::AccessPolicy::AccessError) { @access_policy.verify_access!(jwt) }
      end

      should "raise AccessError for an array claim" do
        @access_policy.statements.sole.conditions.sole.claim = "repository_owners"
        jwt = JSON::JWT.new({ iss: "iss", repository_owners: %w[fakeuser] })

        assert_raise(OIDC::AccessPolicy::AccessError) { @access_policy.verify_access!(jwt) }
      end
    end

    context "with a string_matches condition that backtracks without bound" do
      setup do
        # Ruby memoizes most catastrophic patterns, but not one with a backreference.
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [
            operator: "string_matches",
            claim: "sub",
            value: "(a+)+\\1b"
          ]
                                                ])
      end

      should "deny within Regexp.timeout instead of running on" do
        jwt = JSON::JWT.new({ iss: "iss", sub: "a" * 40 })
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        assert_raise(OIDC::AccessPolicy::AccessError) { @access_policy.verify_access!(jwt) }

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

        assert_operator elapsed, :<, Regexp.timeout * 4
      end
    end

    context "with condition with unknown operator" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [
            operator: "unknown",
            claim: "c",
            value: ""
          ]
                                                ])
      end

      should "raise" do
        jwt = JSON::JWT.new({ iss: "iss" })
        assert_raise('Unknown operator "unknown"') { @access_policy.verify_access!(jwt) }
      end

      should "fail to validate" do
        @access_policy.validate

        assert_equal ["is not included in the list"], @access_policy.errors.messages[:"statements[0].conditions[0].operator"]
      end
    end

    context "with condition with wrong value type" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [
            operator: "string_equals",
            claim: "c",
            value: 3
          ]
                                                ])
      end

      should "raise" do
        jwt = JSON::JWT.new({ iss: "iss" })
        assert_raise('Unknown operator "unknown"') { @access_policy.verify_access!(jwt) }
      end

      should "fail to validate" do
        @access_policy.validate

        assert_equal ["must be String"], @access_policy.errors.messages[:"statements[0].conditions[0].value"]
      end
    end
  end

  private

  def access_policy_with_conditions(condition_counts)
    OIDC::AccessPolicy.new(
      statements: condition_counts.map do |condition_count|
        {
          effect: "allow",
          principal: { oidc: "iss" },
          conditions: Array.new(condition_count) do
            { operator: "string_equals", claim: "c", value: "value" }
          end
        }
      end
    )
  end
end

require "test_helper"

class OIDC::AccessPolicyTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  should validate_presence_of :statements

  setup do
    @role = build(:oidc_api_key_role)
  end

  context "#verify_access!" do
    context "with an unknown effect on matching statement" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [{
                                                  effect: "unknown",
          principal: { oidc: "iss" },
          conditions: []
                                                }])
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
        @access_policy = OIDC::AccessPolicy.new(statements: [{
                                                  effect: "deny",
          principal: { oidc: "iss" },
          conditions: []
                                                }])
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
        @access_policy = OIDC::AccessPolicy.new(statements: [{
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [{
            operator: "string_equals",
            claim: "c",
            value: "value"
          }]
                                                }])
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
        @access_policy = OIDC::AccessPolicy.new(statements: [{
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [{
            operator: "string_matches",
            claim: "c",
            value: "\\A[v].{3}e.*"
          }]
                                                }])
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

    context "with condition with unknown operator" do
      setup do
        @access_policy = OIDC::AccessPolicy.new(statements: [{
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [{
            operator: "unknown",
            claim: "c",
            value: ""
          }]
                                                }])
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
        @access_policy = OIDC::AccessPolicy.new(statements: [{
                                                  effect: "allow",
          principal: { oidc: "iss" },
          conditions: [{
            operator: "string_equals",
            claim: "c",
            value: 3
          }]
                                                }])
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
end

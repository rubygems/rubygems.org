require "test_helper"

class PasswordBreachCheckerTest < ActiveSupport::TestCase
  context "#breached?" do
    should "return true for compromised passwords" do
      Unpwn.any_instance.stubs(:acceptable?).returns(false)

      assert_predicate PasswordBreachChecker.new("password123"), :breached?
    end

    should "return false for safe passwords" do
      Unpwn.any_instance.stubs(:pwned?).returns(false)

      refute_predicate PasswordBreachChecker.new("very-secure-password"), :breached?
    end

    should "return true for nil password" do
      assert_predicate PasswordBreachChecker.new(nil), :breached?
    end

    should "return true for empty password" do
      assert_predicate PasswordBreachChecker.new(""), :breached?
    end

    should "return false and increment counter on timeout" do
      Pwned::Password.any_instance.stubs(:pwned?).raises(Pwned::TimeoutError)
      StatsD.expects(:increment).with("login.hibp_check.error")

      refute_predicate PasswordBreachChecker.new("password123"), :breached?
    end

    should "return false and increment counter on API error" do
      Pwned::Password.any_instance.stubs(:pwned?).raises(Pwned::Error)
      StatsD.expects(:increment).with("login.hibp_check.error")

      refute_predicate PasswordBreachChecker.new("password123"), :breached?
    end
  end
end

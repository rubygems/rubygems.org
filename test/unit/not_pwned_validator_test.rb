require "test_helper"

class NotPwnedValidatorTest < ActiveSupport::TestCase
  class Model
    include ActiveModel::Validations

    attr_accessor :password
  end

  def create_model(password)
    Model.new.tap { |model| model.password = password }
  end

  context "when not pwned" do
    should "report the model as valid" do
      Model.validates :password, not_pwned: { message: "has previously appeared in a data breach", enable_in_testing: true }
      model = create_model("this is totally not pwned")

      RestClient::Request.expects(:execute).at_least_once.returns(stub(body: "02A9ABF721849928613FD023AFC9136E7FC:1"))

      assert model.valid?
      assert_nil model.errors[:password].first
    end
  end

  context "when pwned" do
    should "marks the model as invalid" do
      Model.validates :password, not_pwned: { message: "has previously appeared in a data breach", enable_in_testing: true }
      model = create_model("1234567890")

      RestClient::Request.expects(:execute).at_least_once.returns(stub(body: "7ACBA4F54F55AAFC33BB06BBBF6CA803E9A:2250015"))

      refute model.valid?
      assert_contains model.errors[:password], "has previously appeared in a data breach"
    end
  end
end

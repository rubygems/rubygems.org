require "test_helper"

class BaseActionTest < ActiveSupport::TestCase
  test "handles errors" do
    raises_on_each = Class.new do
      def each
        raise "Cannot enumerate"
      end
    end.new
    action = BaseAction.new

    args = {
      fields: {
        comment: "Sufficiently detailed"
      },
      current_user: create(:admin_github_user, :is_admin),
      resource: nil,
      models: raises_on_each
    }

    action.handle(**args)

    assert_equal [{ type: :error, body: "Cannot enumerate" }], action.response[:messages]
    assert action.response[:keep_modal_open]
  end
end

require "test_helper"

class DynamicErrorsHelperTest < ActionView::TestCase
  test "returns a div with the errors if the object is invalid" do
    user = build(:user, email: nil)
    user.valid?
    expected_dom = %(<div class="errorExplanation" id="errorExplanation"><h2>2 errors prohibited this user from being saved</h2><p>There were \
problems with the following fields:</p><ul><li>Email address is not a valid email</li><li>Email address can't be blank</li></ul></div>)

    assert_dom_equal expected_dom, error_messages_for(user)
  end

  test "returns empty if the object is valid" do
    user = build(:user)
    user.valid?

    assert_empty error_messages_for(user)
  end
end

require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  should "produce ssl urls" do
    expected = new_session_url(:protocol => 'https')
    actual = ssl_url_for :controller => 'clearance/sessions', :action => 'new'
    assert_equal expected, actual
  end
end

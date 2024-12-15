require "test_helper"

class UrlHelperTest < ActionView::TestCase
  context"append_https" do
    should "return url if it begins with https" do
      assert_equal "https://www.awesomesite.com", append_https("https://www.awesomesite.com")
    end
    should "return empty string if url is empty" do
      assert_equal "", append_https("")
    end

    should "return link with https if it does not begin with https" do
      assert_equal "https://javascript:alert('hello');", append_https("javascript:alert('hello');")
    end

    should "return empty string if url is nil" do
      assert_equal "", append_https(nil)
    end
  end 
end 
require "test_helper"

class UrlHelperTest < ActionView::TestCase
  context "prepend_https" do
    should "return url if it begins with https" do
      assert_equal "https://www.awesomesite.com", prepend_https("https://www.awesomesite.com")
    end
    should "return empty string if url is empty" do
      assert_equal "", prepend_https("")
    end

    should "return link with https if it does not begin with https" do
      assert_equal "https://javascript:alert('hello');", prepend_https("javascript:alert('hello');")
    end

    should "return empty string if url is nil" do
      assert_equal "", prepend_https(nil)
    end
  end
end

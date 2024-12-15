require "test_helper"

class UrlHelperTest < ActionView::TestCase
  include ERB::Util
  context "display_safe_url" do
    should "return url if it begins with https" do
      assert_equal "https://www.awesomesite.com", display_safe_url("https://www.awesomesite.com")
    end
    should "return empty string if url is empty" do
      assert_equal "", display_safe_url("")
    end

    should "display a url starting with http" do
      assert_equal "http://www.awesomesite.com", display_safe_url("http://www.awesomesite.com")
    end

    should "return link with https if it does not begin with https" do
      assert_equal "https://javascript:alert(&#39;hello&#39;);", display_safe_url("javascript:alert('hello');")
    end

    should "escape html" do 
      assert_equal "https://&lt;script&gt;alert(&#39;hello&#39;);&lt;/script&gt;https://www", display_safe_url("<script>alert('hello');</script>https://www")
    end 

    should "prepend https if url does not begin with http or https" do 
      assert_equal "https://www.awesomesite.com/https://javascript:alert(&#39;hello&#39;);", display_safe_url("www.awesomesite.com/https://javascript:alert('hello');")
    end 

    should "return empty string if url is nil" do
      assert_equal "", display_safe_url(nil)
    end
  end
end

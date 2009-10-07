require 'test_helper'

class RedirectorTest < ActiveSupport::TestCase
  def app
    Redirector.new
  end

  %w[/book
     /book/42
     /chapter/58
     /read/book/2
     /export
     /shelf/9000
     /syndicate.xml].each do |uri|
    should "redirect to docs.rubygems.org when #{uri} is hit" do
      get uri
      assert_equal 301, last_response.status
      assert_equal "http://docs.rubygems.org#{uri}", last_response.headers["Location"]
    end
  end
end

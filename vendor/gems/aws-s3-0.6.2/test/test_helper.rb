require 'test/unit'
$:.unshift File.dirname(__FILE__) + '/../lib'
require 'aws/s3'
require File.dirname(__FILE__) + '/mocks/fake_response'
require File.dirname(__FILE__) + '/fixtures'
begin
  require_library_or_gem 'ruby-debug'
rescue LoadError
end
require_library_or_gem 'flexmock'
require_library_or_gem 'flexmock/test_unit'


# Data copied from http://docs.amazonwebservices.com/AmazonS3/2006-03-01/RESTAuthentication.html
module AmazonDocExampleData
  module Example1
    module_function
    
      def request
        request = Net::HTTP::Put.new('/quotes/nelson')
        request['Content-Md5']       = 'c8fdb181845a4ca6b8fec737b3581d76'
        request['Content-Type']      = 'text/html'
        request['Date']              = 'Thu, 17 Nov 2005 18:49:58 GMT'
        request['X-Amz-Meta-Author'] = 'foo@bar.com'
        request['X-Amz-Magic']       = 'abracadabra'
        request
      end
  
      def canonical_string
        "PUT\nc8fdb181845a4ca6b8fec737b3581d76\ntext/html\nThu, 17 Nov 2005 18:49:58 GMT\nx-amz-magic:abracadabra\nx-amz-meta-author:foo@bar.com\n/quotes/nelson"
      end
      
      def access_key_id
        '44CF9590006BF252F707'
      end
      
      def secret_access_key
        'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV'
      end
      
      def signature
        'jZNOcbfWmD/A/f3hSvVzXZjM2HU='
      end
      
      def authorization_header
        'AWS 44CF9590006BF252F707:jZNOcbfWmD/A/f3hSvVzXZjM2HU='
      end
  end
  
  module Example3
    module_function
    
      def request
        request = Net::HTTP::Get.new('/quotes/nelson')
        request['Date'] = date
        request
      end
      
      def date
        'Thu Mar  9 01:24:20 CST 2006'
      end
      
      def access_key_id
        Example1.access_key_id
      end
      
      def secret_access_key
        Example1.secret_access_key
      end
      
      def expires
        1141889120
      end
      
      def query_string
        'AWSAccessKeyId=44CF9590006BF252F707&Expires=1141889120&Signature=vjbyPxybdZaNmGa%2ByT272YEAiv4%3D'
      end
      
      def canonical_string
        "GET\n\n\n1141889120\n/quotes/nelson"
      end
      
  end
end

class Test::Unit::TestCase
  include AWS::S3
  
  def sample_proxy_settings
    {:host => 'http://google.com', :port => 8080, :user => 'marcel', :password => 'secret'}
  end
  
  def mock_connection_for(klass, options = {})
    data = options[:returns]
    return_values = case data
    when Hash
      FakeResponse.new(data)
    when Array
      data.map {|hash| FakeResponse.new(hash)}
    else
      abort "Response data for mock connection must be a Hash or an Array. Was #{data.inspect}."
    end
    
    connection = flexmock('Mock connection') do |mock|
      mock.should_receive(:request).and_return(*return_values).at_least.once
    end

    flexmock(klass).should_receive(:connection).and_return(connection)
  end
end
require File.dirname(__FILE__) + '/helper'

class NotifierTest < Test::Unit::TestCase
  context "Sending a notice" do
    should "not fail without rails environment" do
      assert_nothing_raised do
        HoptoadNotifier.environment_info
      end
    end

    context "with an exception" do
      setup do
        @sender    = HoptoadNotifier::Sender.new
        @backtrace = caller
        @exception = begin
          raise
        rescue => caught_exception
          caught_exception
        end
        @options   = {:error_message => "123",
                      :backtrace => @backtrace}
        HoptoadNotifier.instance_variable_set("@backtrace_filters", [])
        HoptoadNotifier::Sender.expects(:new).returns(@sender)
        @sender.stubs(:public_environment?).returns(true)
        HoptoadNotifier.stubs(:environment_info)
      end

      context "when using an HTTP Proxy" do
        setup do
          @body = 'body'
          @response = stub(:body => @body)
          @http = stub(:post => @response, :read_timeout= => nil, :open_timeout= => nil, :use_ssl= => nil)
          @sender.stubs(:logger).returns(stub(:error => nil, :info => nil))
          @proxy = stub
          @proxy.stubs(:new).returns(@http)

          HoptoadNotifier.port = nil
          HoptoadNotifier.host = nil
          HoptoadNotifier.secure = false

          Net::HTTP.expects(:Proxy).with(
            HoptoadNotifier.proxy_host,
            HoptoadNotifier.proxy_port,
            HoptoadNotifier.proxy_user,
            HoptoadNotifier.proxy_pass
          ).returns(@proxy)
        end

        context "on notify" do
          setup { HoptoadNotifier.notify(@exception) }

          before_should "post to Hoptoad" do
            url = "http://hoptoadapp.com:80/notices/"
            uri = URI.parse(url)
            URI.expects(:parse).with(url).returns(uri)
            @http.expects(:post).with(uri.path, anything, anything).returns(@response)
          end
        end
      end

      context "when stubbing out Net::HTTP" do
        setup do
          @body = 'body'
          @response = stub(:body => @body)
          @http = stub(:post => @response, :read_timeout= => nil, :open_timeout= => nil, :use_ssl= => nil)
          @sender.stubs(:logger).returns(stub(:error => nil, :info => nil))
          Net::HTTP.stubs(:new).returns(@http)
          HoptoadNotifier.port = nil
          HoptoadNotifier.host = nil
          HoptoadNotifier.proxy_host = nil
        end

        context "on notify" do
          setup { HoptoadNotifier.notify(@exception) }

          before_should "post to the right url for non-ssl" do
            HoptoadNotifier.secure = false
            url = "http://hoptoadapp.com:80/notices/"
            uri = URI.parse(url)
            URI.expects(:parse).with(url).returns(uri)
            @http.expects(:post).with(uri.path, anything, anything).returns(@response)
          end

          before_should "post to the right path" do
            @http.expects(:post).with("/notices/", anything, anything).returns(@response)
          end

          before_should "call send_to_hoptoad" do
            @sender.expects(:send_to_hoptoad)
          end

          before_should "default the open timeout to 2 seconds" do
            HoptoadNotifier.http_open_timeout = nil
            @http.expects(:open_timeout=).with(2)
          end

          before_should "default the read timeout to 5 seconds" do
            HoptoadNotifier.http_read_timeout = nil
            @http.expects(:read_timeout=).with(5)
          end

          before_should "allow override of the open timeout" do
            HoptoadNotifier.http_open_timeout = 4
            @http.expects(:open_timeout=).with(4)
          end

          before_should "allow override of the read timeout" do
            HoptoadNotifier.http_read_timeout = 10
            @http.expects(:read_timeout=).with(10)
          end

          before_should "connect to the right port for ssl" do
            HoptoadNotifier.secure = true
            Net::HTTP.expects(:new).with("hoptoadapp.com", 443).returns(@http)
          end

          before_should "connect to the right port for non-ssl" do
            HoptoadNotifier.secure = false
            Net::HTTP.expects(:new).with("hoptoadapp.com", 80).returns(@http)
          end

          before_should "use ssl if secure" do
            HoptoadNotifier.secure = true
            HoptoadNotifier.host = 'example.org'
            Net::HTTP.expects(:new).with('example.org', 443).returns(@http)
          end

          before_should "not use ssl if not secure" do
            HoptoadNotifier.secure = nil
            HoptoadNotifier.host = 'example.org'
            Net::HTTP.expects(:new).with('example.org', 80).returns(@http)
          end
        end
      end

      should "send as if it were a normally caught exception" do
        @sender.expects(:notify_hoptoad).with(@exception)
        HoptoadNotifier.notify(@exception)
      end

      should "make sure the exception is munged into a hash" do
        options = HoptoadNotifier.default_notice_options.merge({
          :backtrace     => @exception.backtrace,
          :environment   => ENV.to_hash,
          :error_class   => @exception.class.name,
          :error_message => "#{@exception.class.name}: #{@exception.message}",
          :api_key       => HoptoadNotifier.api_key,
        })
        @sender.expects(:send_to_hoptoad).with(:notice => options)
        HoptoadNotifier.notify(@exception)
      end

      should "parse massive one-line exceptions into multiple lines" do
        @original_backtrace = "one big line\n   separated\n      by new lines\nand some spaces"
        @expected_backtrace = ["one big line", "separated", "by new lines", "and some spaces"]
        @exception.set_backtrace [@original_backtrace]

        options = HoptoadNotifier.default_notice_options.merge({
          :backtrace     => @expected_backtrace,
          :environment   => ENV.to_hash,
          :error_class   => @exception.class.name,
          :error_message => "#{@exception.class.name}: #{@exception.message}",
          :api_key       => HoptoadNotifier.api_key,
        })

        @sender.expects(:send_to_hoptoad).with(:notice => options)
        HoptoadNotifier.notify(@exception)
      end
    end

    context "without an exception" do
      setup do
        @sender    = HoptoadNotifier::Sender.new
        @backtrace = caller
        @options   = {:error_message => "123",
                      :backtrace => @backtrace}
        HoptoadNotifier::Sender.expects(:new).returns(@sender)
      end

      should "send sensible defaults" do
        @sender.expects(:notify_hoptoad).with(@options)
        HoptoadNotifier.notify(:error_message => "123", :backtrace => @backtrace)
      end
    end
  end
end

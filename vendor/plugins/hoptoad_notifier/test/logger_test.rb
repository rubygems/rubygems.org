require File.dirname(__FILE__) + '/helper'

class LoggerTest < Test::Unit::TestCase
  class ::LoggerController < ::ActionController::Base
    include HoptoadNotifier::Catcher
    include TestMethods

    def rescue_action e
      rescue_action_in_public e
    end
  end

  def stub_http(response)
    @http = stub(:post => response,
                 :read_timeout= => nil,
                 :open_timeout= => nil,
                 :use_ssl= => nil)
    Net::HTTP.stubs(:new).returns(@http)
  end

  def stub_controller
    ::ActionController::Base.logger = Logger.new(StringIO.new)
    @controller = ::LoggerController.new
    @controller.stubs(:public_environment?).returns(true)
    @controller.stubs(:rescue_action_in_public_without_hoptoad)
    HoptoadNotifier.stubs(:environment_info)
  end

  context "notifier is configured normally" do
    before_should "report that notifier is ready" do
      HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Notifier (.*) ready/ }
    end

    setup do
      HoptoadNotifier.configure { }
    end

    context "controller is hooked up to the notifier" do
      setup do
        stub_controller
      end

      context "expection is raised and notification is successful" do
        before_should "print environment info" do
          HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Environment Info:/ }
        end

        setup do
          stub_http(Net::HTTPSuccess)
          request("do_raise")
        end
      end

      context "exception is raised and notification fails" do
        before_should "print environment info" do
          HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Environment Info:/ }
        end

        setup do
          stub_http(Net::HTTPError)
          request("do_raise")
        end
      end

      context "exception is raised and notification fails with response body" do
        before_should "print environment info and response" do
          HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Environment Info:/ }
          HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Response from Hoptoad:/ }
        end

        setup do
          response = Net::HTTPSuccess.new(nil, nil, nil)
          response.stubs(:body => "test")
          stub_http(response)
          request("do_raise")
        end
      end
    end
  end

  context "verbose logging is on" do
    setup do
      stub_controller
    end

    context "exception is raised and notification succeeds" do
      before_should "print environment info and response body" do
        HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Environment Info:/ }
        HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Response from Hoptoad:/ }
      end

      setup do
        response = Net::HTTPSuccess.new(nil, nil, nil)
        response.stubs(:body => "test")
        stub_http(response)
        request("do_raise")
      end
    end

    context "exception is raised and notification fails" do
      before_should "print environment info and response body" do
        HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Environment Info:/ }
        HoptoadNotifier.expects(:write_verbose_log).with { |message| message =~ /Response from Hoptoad:/ }
      end

      setup do
        response = Net::HTTPError.new(nil, nil)
        response.stubs(:body => "test")
        stub_http(response)
        request("do_raise")
      end
    end
  end
end

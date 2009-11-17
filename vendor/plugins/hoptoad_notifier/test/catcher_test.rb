require File.dirname(__FILE__) + '/helper'

class CatcherTest < Test::Unit::TestCase

  include DefinesConstants

  def setup
    super
    reset_config
    HoptoadNotifier.sender = CollectingSender.new
    define_constant('RAILS_ROOT', '/path/to/rails/root')
  end

  def ignore(exception_class)
    HoptoadNotifier.configuration.ignore << exception_class
  end

  def build_controller_class(&definition)
    returning Class.new(ActionController::Base) do |klass|
      klass.__send__(:include, HoptoadNotifier::Catcher)
      klass.class_eval(&definition) if definition
      define_constant('HoptoadTestController', klass)
    end
  end

  def assert_sent_hash(hash, xpath)
    hash.each do |key, value|
      element_xpath = "#{xpath}/var[@key = '#{key}']"
      if value.respond_to?(:to_hash)
        assert_sent_hash value.to_hash, element_xpath
      else
        assert_sent_element value.to_s, element_xpath
      end
    end
  end

  def assert_sent_element(value, xpath)
    assert_valid_node last_sent_notice_document, xpath, value
  end

  def assert_sent_request_info_for(request)
    params = request.parameters.to_hash
    assert_sent_hash params, '/notice/request/params'
    assert_sent_element params['controller'], '/notice/request/component'
    assert_sent_element params['action'], '/notice/request/action'
    assert_sent_element "#{request.protocol}#{request.host}#{request.request_uri}",
                        '/notice/request/url'
    assert_sent_hash request.env, '/notice/request/cgi-data'
  end

  def sender
    HoptoadNotifier.sender
  end

  def last_sent_notice_xml
    sender.collected.last
  end

  def last_sent_notice_document
    assert_not_nil xml = last_sent_notice_xml, "No xml was sent"
    Nokogiri::XML.parse(xml)
  end

  def process_action(opts = {}, &action)
    opts[:request]  ||= ActionController::TestRequest.new
    opts[:response] ||= ActionController::TestResponse.new
    klass = build_controller_class do
      cattr_accessor :local
      define_method(:index, &action)
      def local_request?
        local
      end
    end
    if opts[:filters]
      klass.filter_parameter_logging *opts[:filters]
    end
    if opts[:user_agent]
      if opts[:request].respond_to?(:user_agent=)
        opts[:request].user_agent = opts[:user_agent]
      else
        opts[:request].env["HTTP_USER_AGENT"] = opts[:user_agent]
      end
    end
    klass.consider_all_requests_local = opts[:all_local]
    klass.local                       = opts[:local]
    controller = klass.new
    controller.stubs(:rescue_action_in_public_without_hoptoad)
    opts[:request].query_parameters = opts[:request].query_parameters.merge(opts[:params] || {})
    opts[:request].session = ActionController::TestSession.new(opts[:session] || {})
    controller.process(opts[:request], opts[:response])
    controller
  end

  def process_action_with_manual_notification(args = {})
    process_action(args) do
      notify_hoptoad(:error_message => 'fail')
      # Rails will raise a template error if we don't render something
      render :nothing => true
    end
  end

  def process_action_with_automatic_notification(args = {})
    process_action(args) { raise "Hello" }
  end

  should "deliver notices from exceptions raised in public requests" do
    process_action_with_automatic_notification
    assert_caught_and_sent
  end

  should "not deliver notices from exceptions in local requests" do
    process_action_with_automatic_notification(:local => true)
    assert_caught_and_not_sent
  end

  should "not deliver notices from exceptions when all requests are local" do
    process_action_with_automatic_notification(:all_local => true)
    assert_caught_and_not_sent
  end

  should "not deliver notices from actions that don't raise" do
    controller = process_action { render :text => 'Hello' }
    assert_caught_and_not_sent
    assert_equal 'Hello', controller.response.body
  end

  should "not deliver ignored exceptions raised by actions" do
    ignore(RuntimeError)
    process_action_with_automatic_notification
    assert_caught_and_not_sent
  end

  should "deliver ignored exception raised manually" do
    ignore(RuntimeError)
    process_action_with_manual_notification
    assert_caught_and_sent
  end

  should "deliver manually sent notices in public requests" do
    process_action_with_manual_notification
    assert_caught_and_sent
  end

  should "not deliver manually sent notices in local requests" do
    process_action_with_manual_notification(:local => true)
    assert_caught_and_not_sent
  end

  should "not deliver manually sent notices when all requests are local" do
    process_action_with_manual_notification(:all_local => true)
    assert_caught_and_not_sent
  end

  should "continue with default behavior after delivering an exception" do
    controller = process_action_with_automatic_notification(:public => true)
    # TODO: can we test this without stubbing?
    assert_received(controller, :rescue_action_in_public_without_hoptoad)
  end

  should "not create actions from Hoptoad methods" do
    controller = build_controller_class.new
    assert_equal [], HoptoadNotifier::Catcher.instance_methods
  end

  should "ignore exceptions when user agent is being ignored by regular expression" do
    HoptoadNotifier.configuration.ignore_user_agent_only = [/Ignored/]
    process_action_with_automatic_notification(:user_agent => 'ShouldBeIgnored')
    assert_caught_and_not_sent
  end

  should "ignore exceptions when user agent is being ignored by string" do
    HoptoadNotifier.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
    process_action_with_automatic_notification(:user_agent => 'IgnoredUserAgent')
    assert_caught_and_not_sent
  end

  should "not ignore exceptions when user agent is not being ignored" do
    HoptoadNotifier.configuration.ignore_user_agent_only = ['IgnoredUserAgent']
    process_action_with_automatic_notification(:user_agent => 'NonIgnoredAgent')
    assert_caught_and_sent
  end

  should "send session data for manual notifications" do
    data = { 'one' => 'two' }
    process_action_with_manual_notification(:session => data)
    assert_sent_hash data, "/notice/request/session"
  end

  should "send session data for automatic notification" do
    data = { 'one' => 'two' }
    process_action_with_automatic_notification(:session => data)
    assert_sent_hash data, "/notice/request/session"
  end

  should "send request data for manual notification" do
    params = { 'controller' => "hoptoad_test", 'action' => "index" }
    controller = process_action_with_manual_notification(:params => params)
    assert_sent_request_info_for controller.request
  end

  should "send request data for automatic notification" do
    params = { 'controller' => "hoptoad_test", 'action' => "index" }
    controller = process_action_with_automatic_notification(:params => params)
    assert_sent_request_info_for controller.request
  end

  should "use standard rails logging filters on params and env" do
    filtered_params = { "abc" => "123",
                        "def" => "456",
                        "ghi" => "[FILTERED]" }
    ENV['ghi'] = 'abc'
    filtered_env = { 'ghi' => '[FILTERED]' }
    filtered_cgi = { 'REQUEST_METHOD' => '[FILTERED]' }

    process_action_with_automatic_notification(:filters => [:ghi, :request_method],
                                               :params => { "abc" => "123",
                                                            "def" => "456",
                                                            "ghi" => "789" })
    assert_sent_hash filtered_params, '/notice/request/params'
    assert_sent_hash filtered_cgi, '/notice/request/cgi-data'
  end

  context "for a local error with development lookup enabled" do
    setup do
      HoptoadNotifier.configuration.development_lookup = true
      HoptoadNotifier.stubs(:build_lookup_hash_for).returns({ :awesome => 2 })

      @controller = process_action_with_automatic_notification(:local => true)
      @response   = @controller.response
    end

    should "append custom CSS and JS to response body for a local error" do
      assert_match /text\/css/, @response.body
      assert_match /text\/javascript/, @response.body
    end

    should "contain host, API key and notice JSON" do
      assert_match HoptoadNotifier.configuration.host.to_json, @response.body
      assert_match HoptoadNotifier.configuration.api_key.to_json, @response.body
      assert_match ({ :awesome => 2 }).to_json, @response.body
    end
  end

  context "for a local error with development lookup disabled" do
    setup do
      HoptoadNotifier.configuration.development_lookup = false

      @controller = process_action_with_automatic_notification(:local => true)
      @response   = @controller.response
    end

    should "not append custom CSS and JS to response for a local error" do
      assert_no_match /text\/css/, @response.body
      assert_no_match /text\/javascript/, @response.body
    end
  end

end

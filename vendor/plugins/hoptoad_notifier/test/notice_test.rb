require File.dirname(__FILE__) + '/helper'

class NoticeTest < Test::Unit::TestCase

  include DefinesConstants

  def configure
    returning HoptoadNotifier::Configuration.new do |config|
      config.api_key = 'abc123def456'
    end
  end

  def build_notice(args = {})
    configuration = args.delete(:configuration) || configure
    HoptoadNotifier::Notice.new(configuration.merge(args))
  end

  def stub_request(attrs = {})
    stub('request', { :parameters  => { 'one' => 'two' },
                      :protocol    => 'http',
                      :host        => 'some.host',
                      :request_uri => '/some/uri',
                      :session     => { :to_hash => { 'a' => 'b' } },
                      :env         => { 'three' => 'four' } }.update(attrs))
  end

  should "set the api key" do
    api_key = 'key'
    notice = build_notice(:api_key => api_key)
    assert_equal api_key, notice.api_key
  end

  should "accept a project root" do
    project_root = '/path/to/project'
    notice = build_notice(:project_root => project_root)
    assert_equal project_root, notice.project_root
  end

  should "accept a component" do
    assert_equal 'users_controller', build_notice(:component => 'users_controller').controller
  end

  should "alias the component as controller" do
    assert_equal 'users_controller', build_notice(:controller => 'users_controller').component
    assert_equal 'users_controller', build_notice(:component => 'users_controller').controller
  end

  should "accept a action" do
    assert_equal 'index', build_notice(:action => 'index').action
  end

  should "accept a url" do
    url = 'http://some.host/uri'
    notice = build_notice(:url => url)
    assert_equal url, notice.url
  end

  should "accept a backtrace from an exception or hash" do
    array = ["user.rb:34:in `crazy'"]
    exception = build_exception
    exception.set_backtrace array
    backtrace = HoptoadNotifier::Backtrace.parse(array)
    notice_from_exception = build_notice(:exception => exception)


    assert_equal notice_from_exception.backtrace,
                 backtrace,
                 "backtrace was not correctly set from an exception"

    notice_from_hash = build_notice(:backtrace => array)
    assert_equal notice_from_hash.backtrace,
                 backtrace,
                 "backtrace was not correctly set from a hash"
  end

  should "set the error class from an exception or hash" do
    assert_accepts_exception_attribute :error_class do |exception|
      exception.class.name
    end
  end

  should "set the error message from an exception or hash" do
    assert_accepts_exception_attribute :error_message do |exception|
      "#{exception.class.name}: #{exception.message}"
    end
  end

  should "accept parameters from a request or hash" do
    parameters = { 'one' => 'two' }
    notice_from_hash = build_notice(:parameters => parameters)
    assert_equal notice_from_hash.parameters, parameters
  end

  should "accept session data from a session[:data] hash" do
    data = { 'one' => 'two' }
    notice = build_notice(:session => { :data => data })
    assert_equal data, notice.session_data
  end

  should "accept session data from a session_data hash" do
    data = { 'one' => 'two' }
    notice = build_notice(:session_data => data)
    assert_equal data, notice.session_data
  end

  should "accept an environment name" do
    assert_equal 'development', build_notice(:environment_name => 'development').environment_name
  end

  should "accept CGI data from a hash" do
    data = { 'string' => 'value' }
    notice = build_notice(:cgi_data => data)
    assert_equal data, notice.cgi_data, "should take CGI data from a hash"
  end

  should "accept notifier information" do
    params = { :notifier_name    => 'a name for a notifier',
               :notifier_version => '1.0.5',
               :notifier_url     => 'http://notifiers.r.us/download' }
    notice = build_notice(params)
    assert_equal params[:notifier_name], notice.notifier_name
    assert_equal params[:notifier_version], notice.notifier_version
    assert_equal params[:notifier_url], notice.notifier_url
  end

  should "set sensible defaults without an exception" do
    backtrace = HoptoadNotifier::Backtrace.parse(caller)
    notice = build_notice

    assert_equal 'Notification', notice.error_message
    assert_array_starts_with backtrace.lines, notice.backtrace.lines
    assert_equal({}, notice.parameters)
    assert_equal({}, notice.session_data)
  end

  should "use the caller as the backtrace for an exception without a backtrace" do
    backtrace = HoptoadNotifier::Backtrace.parse(caller)
    notice = build_notice(:exception => StandardError.new('error'), :backtrace => nil)

    assert_array_starts_with backtrace.lines, notice.backtrace.lines
  end

  should "convert unserializable objects to strings" do
    assert_serializes_hash(:parameters)
  end

  should "filter parameters" do
    filters = %w(abc def)
    params  = { 'abc' => "123", 'def' => "456", 'ghi' => "789" }

    notice = build_notice(:params_filters => filters, :parameters => params)

    assert_equal({ 'abc' => "[FILTERED]", 'def' => "[FILTERED]", 'ghi' => "789" },
                 notice.parameters)
  end

  context "a Notice turned into XML" do
    setup do
      HoptoadNotifier.configure do |config|
        config.api_key = "1234567890"
      end

      @exception = build_exception

      @notice = build_notice({
        :notifier_name    => 'a name',
        :notifier_version => '1.2.3',
        :notifier_url     => 'http://some.url/path',
        :exception        => @exception,
        :controller       => "controller",
        :action           => "action",
        :url              => "http://url.com",
        :parameters       => { "paramskey"     => "paramsvalue",
                               "nestparentkey" => { "nestkey" => "nestvalue" } },
        :session_data     => { "sessionkey" => "sessionvalue" },
        :cgi_data         => { "cgikey" => "cgivalue" },
        :project_root     => "RAILS_ROOT",
        :environment_name => "RAILS_ENV"
      })

      @xml = @notice.to_xml

      @document = Nokogiri::XML::Document.parse(@xml)
    end

    should "validate against the XML schema" do
      assert_valid_notice_document @document
    end

    should "serialize a Notice to XML when sent #to_xml" do
      assert_valid_node(@document, "//api-key", @notice.api_key)

      assert_valid_node(@document, "//notifier/name",    @notice.notifier_name)
      assert_valid_node(@document, "//notifier/version", @notice.notifier_version)
      assert_valid_node(@document, "//notifier/url",     @notice.notifier_url)

      assert_valid_node(@document, "//error/class",   @notice.error_class)
      assert_valid_node(@document, "//error/message", @notice.error_message)

      assert_valid_node(@document, "//error/backtrace/line/@number", @notice.backtrace.lines.first.number)
      assert_valid_node(@document, "//error/backtrace/line/@file", @notice.backtrace.lines.first.file)
      assert_valid_node(@document, "//error/backtrace/line/@method", @notice.backtrace.lines.first.method)

      assert_valid_node(@document, "//request/url",        @notice.url)
      assert_valid_node(@document, "//request/component", @notice.controller)
      assert_valid_node(@document, "//request/action",     @notice.action)

      assert_valid_node(@document, "//request/params/var/@key",     "paramskey")
      assert_valid_node(@document, "//request/params/var",          "paramsvalue")
      assert_valid_node(@document, "//request/params/var/@key",     "nestparentkey")
      assert_valid_node(@document, "//request/params/var/var/@key", "nestkey")
      assert_valid_node(@document, "//request/params/var/var",      "nestvalue")
      assert_valid_node(@document, "//request/session/var/@key",    "sessionkey")
      assert_valid_node(@document, "//request/session/var",         "sessionvalue")
      assert_valid_node(@document, "//request/cgi-data/var/@key",   "cgikey")
      assert_valid_node(@document, "//request/cgi-data/var",        "cgivalue")

      assert_valid_node(@document, "//server-environment/project-root",     "RAILS_ROOT")
      assert_valid_node(@document, "//server-environment/environment-name", "RAILS_ENV")
    end
  end

  should "not send empty request data" do
    notice = build_notice
    assert_nil notice.url
    assert_nil notice.controller
    assert_nil notice.action

    xml = notice.to_xml
    document = Nokogiri::XML.parse(xml)
    assert_nil document.at('//request/url')
    assert_nil document.at('//request/component')
    assert_nil document.at('//request/action')

    assert_valid_notice_document document
  end

  %w(url controller action).each do |var|
    should "send a request if #{var} is present" do
      notice = build_notice(var.to_sym => 'value')
      xml = notice.to_xml
      document = Nokogiri::XML.parse(xml)
      assert_not_nil document.at('//request')
    end
  end

  %w(parameters cgi_data session_data).each do |var|
    should "send a request if #{var} is present" do
      notice = build_notice(var.to_sym => { 'key' => 'value' })
      xml = notice.to_xml
      document = Nokogiri::XML.parse(xml)
      assert_not_nil document.at('//request')
    end
  end

  should "not ignore an exception not matching ignore filters" do
    notice = build_notice(:error_class       => 'ArgumentError',
                          :ignore            => ['Argument'],
                          :ignore_by_filters => [lambda { |notice| false }])
    assert !notice.ignore?
  end

  should "ignore an exception with a matching error class" do
    notice = build_notice(:error_class => 'ArgumentError',
                          :ignore      => [ArgumentError])
    assert notice.ignore?
  end

  should "ignore an exception with a matching error class name" do
    notice = build_notice(:error_class => 'ArgumentError',
                          :ignore      => ['ArgumentError'])
    assert notice.ignore?
  end

  should "ignore an exception with a matching filter" do
    filter = lambda {|notice| notice.error_class == 'ArgumentError' }
    notice = build_notice(:error_class       => 'ArgumentError',
                          :ignore_by_filters => [filter])
    assert notice.ignore?
  end

  should "not raise without an ignore list" do
    notice = build_notice(:ignore => nil, :ignore_by_filters => nil)
    assert_nothing_raised do
      notice.ignore?
    end
  end

  should "act like a hash" do
    notice = build_notice(:error_message => 'some message')
    assert_equal notice.error_message, notice[:error_message]
  end

  should "return params on notice[:request][:params]" do
    params = { 'one' => 'two' }
    notice = build_notice(:parameters => params)
    assert_equal params, notice[:request][:params]
  end

  def assert_accepts_exception_attribute(attribute, args = {}, &block)
    exception = build_exception
    block ||= lambda { exception.send(attribute) }
    value = block.call(exception)

    notice_from_exception = build_notice(args.merge(:exception => exception))

    assert_equal notice_from_exception.send(attribute),
                 value,
                 "#{attribute} was not correctly set from an exception"

    notice_from_hash = build_notice(args.merge(attribute => value))
    assert_equal notice_from_hash.send(attribute),
                 value,
                 "#{attribute} was not correctly set from a hash"
  end

  def assert_serializes_hash(attribute)
    [File.open(__FILE__), Proc.new { puts "boo!" }, Module.new].each do |object|
      hash = {
        :strange_object => object,
        :sub_hash => {
          :sub_object => object
        },
        :array => [object]
      }
      notice = build_notice(attribute => hash)
      hash = notice.send(attribute)
      assert_equal object.to_s, hash[:strange_object], "objects should be serialized"
      assert_kind_of Hash, hash[:sub_hash], "subhashes should be kept"
      assert_equal object.to_s, hash[:sub_hash][:sub_object], "subhash members should be serialized"
      assert_kind_of Array, hash[:array], "arrays should be kept"
      assert_equal object.to_s, hash[:array].first, "array members should be serialized"
    end
  end

  def assert_valid_notice_document(document)
    xsd_path = File.join(File.dirname(__FILE__), "hoptoad_2_0.xsd")
    schema = Nokogiri::XML::Schema.new(IO.read(xsd_path))
    errors = schema.validate(document)
    assert errors.empty?, errors.collect{|e| e.message }.join
  end
end

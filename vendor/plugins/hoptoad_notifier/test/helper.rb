require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'thoughtbot-shoulda', ">= 2.0.0"
require 'shoulda'

$LOAD_PATH << File.join(File.dirname(__FILE__), *%w[.. vendor ginger lib])
require 'ginger'

require 'action_controller'
require 'action_controller/test_process'
require 'active_record'
require 'active_record/base'
require 'active_support'

require File.join(File.dirname(__FILE__), "..", "lib", "hoptoad_notifier")

RAILS_ROOT = File.join( File.dirname(__FILE__), "rails_root" )
RAILS_ENV  = "test"

begin require 'redgreen'; rescue LoadError; end

module TestMethods
  def rescue_action e
    raise e
  end

  def do_raise
    raise "Hoptoad"
  end

  def do_not_raise
    render :text => "Success"
  end

  def do_raise_ignored
    raise ActiveRecord::RecordNotFound.new("404")
  end

  def do_raise_not_ignored
    raise ActiveRecord::StatementInvalid.new("Statement invalid")
  end

  def manual_notify
    notify_hoptoad(Exception.new)
    render :text => "Success"
  end

  def manual_notify_ignored
    notify_hoptoad(ActiveRecord::RecordNotFound.new("404"))
    render :text => "Success"
  end
end

class HoptoadController < ActionController::Base
  include TestMethods
end

class Test::Unit::TestCase
  def request(action = nil, method = :get, user_agent = nil, params = {})
    @request = ActionController::TestRequest.new
    @request.action = action ? action.to_s : ""

    if user_agent
      if @request.respond_to?(:user_agent=)
        @request.user_agent = user_agent
      else
        @request.env["HTTP_USER_AGENT"] = user_agent
      end
    end
    @request.query_parameters = @request.query_parameters.merge(params)
    @response = ActionController::TestResponse.new
    @controller.process(@request, @response)
  end

  # Borrowed from ActiveSupport 2.3.2
  def assert_difference(expression, difference = 1, message = nil, &block)
    b = block.send(:binding)
    exps = Array.wrap(expression)
    before = exps.map { |e| eval(e, b) }

    yield

    exps.each_with_index do |e, i|
      error = "#{e.inspect} didn't change by #{difference}"
      error = "#{message}.\n#{error}" if message
      assert_equal(before[i] + difference, eval(e, b), error)
    end
  end

  def assert_no_difference(expression, message = nil, &block)
    assert_difference expression, 0, message, &block
  end
end

# Also stolen from AS 2.3.2
class Array
  # Wraps the object in an Array unless it's an Array.  Converts the
  # object to an Array using #to_ary if it implements that.
  def self.wrap(object)
    case object
    when nil
      []
    when self
      object
    else
      if object.respond_to?(:to_ary)
        object.to_ary
      else
        [object]
      end
    end
  end
end

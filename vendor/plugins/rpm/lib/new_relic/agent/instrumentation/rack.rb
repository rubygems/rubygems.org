require 'new_relic/agent/instrumentation/controller_instrumentation'

module NewRelic
  module Agent
    module Instrumentation
      # == Instrumentation for Rack
      #
      # New Relic will instrument a #call method as if it were a controller
      # action, collecting transaction traces and errors.  The middleware will
      # be identified only by it's class, so if you want to instrument multiple
      # actions in a middleware, you need to use
      # NewRelic::Agent::Instrumentation::ControllerInstrumentation::ClassMethods#add_transaction_tracer
      #
      # Example:
      #   require 'new_relic/agent/instrumentation/rack'
      #   class Middleware
      #     def call(env)
      #       ...
      #     end
      #     # Do the include after the call method is defined:
      #     include NewRelic::Agent::Instrumentation::Rack
      #   end
      #
      # == Instrumenting Metal
      #
      # If you are using Metal, be sure and extend the your Metal class with the
      # Rack instrumentation:
      #
      #   require 'new_relic/agent/instrumentation/rack'
      #   class MetalApp
      #     def self.call(env)
      #       ...
      #     end
      #     # Do the include after the call method is defined:
      #     extend NewRelic::Agent::Instrumentation::Rack
      #   end
      #
      # == Overriding the metric name
      #
      # By default the middleware is identified only by its class, but if you want to 
      # be more specific and pass in name, then omit including the Rack instrumentation
      # and instead follow this example:
      #
      #   require 'new_relic/agent/instrumentation/controller_instrumentation'
      #   class Middleware
      #     include NewRelic::Agent::Instrumentation::ControllerInstrumentation
      #     def call(env)
      #       ...
      #     end
      #     add_transaction_tracer :call, :category => :rack, :name => 'my app'
      #   end
      #
      # == Cascading or chained calls
      #
      # You should avoid instrumenting nested calls.  So if you are using Rack::Cascade
      # to fall through the action, or you are chaining through to the next middleware 
      # which will have it's own controller instrumentation, then you will want to
      # instrument only when you are the endpoint.
      #
      # In these cases, you should not include or extend the Rack module but instead
      # include NewRelic::Agent::Instrumentation::ControllerInstrumentation.
      # Here's how that might look:
      #
      #   require 'new_relic/agent/instrumentation/controller_instrumentation'
      #   class MetalApp
      #     extend NewRelic::Agent::Instrumentation::ControllerInstrumentation
      #     def self.call(env)
      #       if should_do_my_thing?
      #         perform_action_with_newrelic_trace(:category => :rack) do
      #           return my_response(env)
      #         end
      #       else
      #         return [404, {"Content-Type" => "text/html"}, ["Not Found"]]
      #       end
      #     end
      #   end
      #      
      module Rack
        def newrelic_request_headers
          @newrelic_env
        end
        def call_with_newrelic(*args)
          @newrelic_env = args.first
          perform_action_with_newrelic_trace(:category => :rack, :params => {:uri => @newrelic_env['REQUEST_PATH']}) do
            result = call_without_newrelic(*args)
            # Ignore cascaded calls
            MetricFrame.abort_transaction! if result.first == 404
            result
          end
        end
        def self.included middleware #:nodoc:
          middleware.class_eval do
            alias call_without_newrelic call
            alias call call_with_newrelic
          end
        end
        include ControllerInstrumentation
        def self.extended middleware #:nodoc:
          middleware.class_eval do
            class << self
              alias call_without_newrelic call
              alias call call_with_newrelic
            end
          end
        end
      end
    end
  end
end

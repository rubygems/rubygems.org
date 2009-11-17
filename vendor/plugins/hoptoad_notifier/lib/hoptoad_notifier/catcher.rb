module HoptoadNotifier
  # Include this module in Controllers in which you want to be notified of errors.
  module Catcher

    # Sets up an alias chain to catch exceptions when Rails does
    def self.included(base) #:nodoc:
      if base.instance_methods.map(&:to_s).include? 'rescue_action_in_public' and !base.instance_methods.map(&:to_s).include? 'rescue_action_in_public_without_hoptoad'
        base.send(:alias_method, :rescue_action_in_public_without_hoptoad, :rescue_action_in_public)
        base.send(:alias_method, :rescue_action_in_public, :rescue_action_in_public_with_hoptoad)
        base.send(:alias_method, :rescue_action_locally_without_hoptoad, :rescue_action_locally)
        base.send(:alias_method, :rescue_action_locally, :rescue_action_locally_with_hoptoad)
      end
    end

    private

    # Overrides the rescue_action method in ActionController::Base, but does not inhibit
    # any custom processing that is defined with Rails 2's exception helpers.
    def rescue_action_in_public_with_hoptoad(exception)
      unless ignore_user_agent?
        HoptoadNotifier.notify_or_ignore(exception, request_data_for_hoptoad)
      end
      rescue_action_in_public_without_hoptoad(exception)
    end

    def rescue_action_locally_with_hoptoad(exception)
      result = rescue_action_locally_without_hoptoad(exception)

      if HoptoadNotifier.configuration.development_lookup
        path   = File.join(File.dirname(__FILE__), '..', 'templates', 'rescue.erb')
        notice = HoptoadNotifier.build_lookup_hash_for(exception, request_data_for_hoptoad)

        result << @template.render(
          :file          => path,
          :use_full_path => false,
          :locals        => { :host    => HoptoadNotifier.configuration.host,
                              :api_key => HoptoadNotifier.configuration.api_key,
                              :notice  => notice })
      end

      result
    end

    # This method should be used for sending manual notifications while you are still
    # inside the controller. Otherwise it works like HoptoadNotifier.notify.
    def notify_hoptoad(hash_or_exception)
      unless consider_all_requests_local || local_request?
        HoptoadNotifier.notify(hash_or_exception, request_data_for_hoptoad)
      end
    end

    def ignore_user_agent? #:nodoc:
      # Rails 1.2.6 doesn't have request.user_agent, so check for it here
      user_agent = request.respond_to?(:user_agent) ? request.user_agent : request.env["HTTP_USER_AGENT"]
      HoptoadNotifier.configuration.ignore_user_agent.flatten.any? { |ua| ua === user_agent }
    end

    def request_data_for_hoptoad
      { :parameters       => filter_if_filtering(params.to_hash),
        :session_data     => session.data,
        :controller       => params[:controller],
        :action           => params[:action],
        :url              => "#{request.protocol}#{request.host}#{request.request_uri}",
        :cgi_data         => filter_if_filtering(request.env),
        :environment_vars => filter_if_filtering(ENV) }
    end

    def filter_if_filtering(hash)
      if respond_to?(:filter_parameters)
        filter_parameters(hash) rescue hash
      else
        hash
      end
    end

  end
end

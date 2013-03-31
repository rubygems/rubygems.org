module SimpleSSLRequirement
  SSL_ENVIRONMENTS = %w(production staging test)

  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      private

      def require_ssl
        if !request.ssl?
          redirect_to "https://#{request.host}#{request.fullpath}"
          flash.keep
        end
      end
    end
  end

  module ClassMethods
    def ssl_required(options={})
      options.reverse_merge!(:environments => SSL_ENVIRONMENTS)

      if options.delete(:environments).include?(Rails.env)
        before_filter :require_ssl, options
      end
    end
  end
end

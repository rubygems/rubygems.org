module SimpleSSLRequirement
  SSL_ENVIRONMENTS = %w(production staging)

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def ssl_required(options = {})
      options.reverse_merge!(environments: SSL_ENVIRONMENTS)
      return unless options.delete(:environments).include?(Rails.env)
      before_action :require_ssl, options
    end
  end

  private

  def require_ssl
    return if request.ssl?
    redirect_to "https://#{request.host}#{request.fullpath}"
    flash.keep
  end
end

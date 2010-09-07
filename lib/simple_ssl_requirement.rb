module SimpleSSLRequirement
  def ssl_required(options={})
    options.reverse_merge!(:environments => %w(production staging test))

    if options.delete(:environments).include?(Rails.env)
      before_filter options do
        if !request.ssl?
          redirect_to "https://#{request.host}#{request.fullpath}"
          flash.keep
        end
      end
    end
  end
end

ActionController::Base.extend SimpleSSLRequirement
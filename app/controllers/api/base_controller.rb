class Api::BaseController < ApplicationController
  skip_before_filter :require_ssl
  before_filter :enable_cross_origin_resource_sharing

  private

  def has_required_params?(*keys)
    if keys.all? {|key| params[key] }
      true
    else
      missing_params = keys.select {|key| !params[key] }
      str = missing_params.size > 1 ? 'params' : 'param'
      render :text => "Request is missing #{str} #{missing_params.map(&:inspect).to_sentence}",
        :status => :bad_request
      false
    end
  end

  def enable_cross_origin_resource_sharing
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = 'GET'
  end
end

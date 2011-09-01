class Api::BaseController < ApplicationController
  skip_before_filter :require_ssl

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
end

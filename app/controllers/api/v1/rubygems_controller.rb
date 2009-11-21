class Api::V1::RubygemsController < ApplicationController
  before_filter :find_gem

  def show
    if @rubygem.hosted?
      render :json => @rubygem.to_json
    else
      render :json => "This gem does not exist.", :status => :not_found
    end
  end
end

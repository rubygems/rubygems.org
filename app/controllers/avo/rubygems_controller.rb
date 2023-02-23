# This controller has been generated to enable Rails' resource routes.
# More information on https://docs.avohq.io/2.0/controllers.html
class Avo::RubygemsController < Avo::ResourcesController
  def set_model
    @model = model_find_scope.find_by! name: params[:id]
  end
end

class MigrationsController < ApplicationController
  before_filter :authenticate_with_api_key, :only => :create

  def create
  end
end

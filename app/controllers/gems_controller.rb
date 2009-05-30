class GemsController < ApplicationController

  def index
    @gems = Rubygem.all
  end
end

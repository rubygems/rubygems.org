class RubygemsController < ApplicationController

  def index
    @gems = Rubygem.all
  end
end

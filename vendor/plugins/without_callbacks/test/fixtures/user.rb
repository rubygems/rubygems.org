require 'lib/without_callbacks'

class User < ActiveRecord::Base
  
  before_save :do_stuff
  
  def after_save
    self.called_after_save = true
  end

  private
  
    def do_stuff
      self.called_before_save = true
    end
  
end
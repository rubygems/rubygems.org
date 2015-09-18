module Gemcutter
  mattr_accessor :admins
  self.admins = Application.config_for("admins")["emails"]
end

module Rstuf
  mattr_accessor :base_url
  mattr_accessor :enabled, default: false
  mattr_accessor :wait_for, default: 1

  def self.enabled?
    enabled
  end
end

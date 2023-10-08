module Rstuf
  mattr_accessor :base_url
  mattr_accessor :enabled

  def self.enabled?
    enabled
  end
end

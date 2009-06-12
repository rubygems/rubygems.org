require 'ginger/configuration'
require 'ginger/scenario'
require 'ginger/kernel'

module Ginger
  module Version
    Major = 1
    Minor = 0
    Tiny  = 0
    
    String = [Major, Minor, Tiny].join('.')
  end
  
  def self.configure(&block)
    yield Ginger::Configuration.instance
  end
end

Kernel.send(:include, Ginger::Kernel)

Ginger::Configuration.detect_scenario_file
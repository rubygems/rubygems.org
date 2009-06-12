require 'singleton'

module Ginger
  class Configuration
    include Singleton
    
    attr_accessor :scenarios, :aliases
    
    def initialize
      @scenarios = []
      @aliases   = {}
    end
    
    def self.detect_scenario_file
      ['.','spec','test'].each do |path|
        require "#{path}/ginger_scenarios" and break if File.exists?("#{path}/ginger_scenarios.rb")
      end
    end
  end
end

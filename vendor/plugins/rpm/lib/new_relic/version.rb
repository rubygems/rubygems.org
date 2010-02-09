#!/usr/bin/ruby
module NewRelic
  module VERSION #:nodoc:
    MAJOR = 2
    MINOR = 10
    TINY  = 2
    EXPERIMENTAL = 2
    STRING = [MAJOR, MINOR, TINY, EXPERIMENTAL].compact.join('.')
  end
  
  # Helper class for managing version comparisons 
  class VersionNumber
    attr_reader :parts
    include Comparable
    def initialize(version_string)
      version_string ||= '1.0.0'
      @parts = version_string.split('.').map{|n| n.to_i }
    end
    def major_version; @parts[0]; end
    def minor_version; @parts[1]; end
    def tiny_version; @parts[2]; end
    
    def <=>(other)
      other = self.class.new(other) if other.is_a? String
      self.class.compare(self.parts, other.parts)
    end
    
    def to_s
      @parts.join(".")
    end
    
    def hash
      @parts.hash
    end
    
    def eql? other
      (self <=> other) == 0
    end
    
    private
    def self.compare(parts1, parts2)
      a, b = parts1.first, parts2.first
      case
        when a.nil? && b.nil? then 0
        when a.nil? then -1
        when b.nil? then 1
        when a == b
          compare(parts1[1..-1], parts2[1..-1])
        else
          a <=> b
      end
    end
  end
end

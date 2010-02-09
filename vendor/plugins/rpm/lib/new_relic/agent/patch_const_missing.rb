# This class is for debugging purposes only.
# It inserts instrumentation into class loading to verify
# that no classes are being loaded on the new relic thread,
# which can cause problems in the class loader code. 
# It is only loaded by agent.rb when a particular newrelic.yml
# option is set.

module ClassLoadingWatcher # :nodoc: all
  
  extend self
  @@background_thread = nil
  @@flag_const_missing = nil
  
  def background_thread
    @@background_thread
  end
  def flag_const_missing
    @@flag_const_missing
  end
  def flag_const_missing=(val)
    @@flag_const_missing = val
  end
  
  def background_thread=(thread)
    @@background_thread = thread
    
    # these tests verify that check is working
=begin
        @@background_thread = nil
        bad = ConstMissingInForegroundThread rescue nil
        @@background_thread = thread
        bad = ConstMissingInBackgroundThread rescue nil
        require 'new_relic/agent/patch_const_missing'
        load 'new_relic/agent/patch_const_missing.rb'
=end
  end
  module SanityCheck 
    def nr_check_for_classloading(*args)
      
      if Thread.current == ClassLoadingWatcher.background_thread    
        nr_error "Agent background thread shouldn't be loading classes (#{args.inspect})"  
      end
    end
    # 
    def nr_check_for_constmissing(*args)
      if ClassLoadingWatcher.flag_const_missing
        nr_error "Classes in Agent should not be loaded via const_missing (#{args.inspect})"        
      end
    end
    private
    def nr_error(msg)
      exception = NewRelic::Agent::BackgroundLoadingError.new(msg)
      backtrace = caller
      backtrace.shift
      exception.set_backtrace(backtrace)
      NewRelic::Agent.instance.error_collector.notice_error(exception, nil)
      msg << "\n" << backtrace.join("\n")
      NewRelic::Control.instance.log.error msg
    end
  end
  def enable_warning
    Object.class_eval do
      if !defined?(non_new_relic_require)
        alias_method :non_new_relic_require, :require
        alias_method :require, :new_relic_require
      end
      
      if !defined?(non_new_relic_load)
        alias_method :non_new_relic_load, :load
        alias_method :load, :new_relic_load
      end
    end
    Module.class_eval do
      if !defined?(non_new_relic_const_missing)
        alias_method :non_new_relic_const_missing, :const_missing
        alias_method :const_missing, :new_relic_const_missing
      end
    end
  end
  
  def disable_warning
    Object.class_eval do
      if defined?(non_new_relic_require)
        alias_method :require, :non_new_relic_require
        undef non_new_relic_require
      end
      
      if defined?(non_new_relic_load)
        alias_method :load, :non_new_relic_load
        undef non_new_relic_load
      end
    end
    Module.class_eval do
      if defined?(non_new_relic_const_missing)
        alias_method :const_missing, :non_new_relic_const_missing
        undef non_new_relic_const_missing
      end
    end
  end
end

class Object # :nodoc:
  include ClassLoadingWatcher::SanityCheck
  
  def new_relic_require(*args)
    nr_check_for_classloading("Object require", *args)    
    non_new_relic_require(*args)
  end
  
  def new_relic_load(*args)
    nr_check_for_classloading("Object load", *args)
    non_new_relic_load(*args)
  end
end


class Module # :nodoc:
  include ClassLoadingWatcher::SanityCheck
  
  def new_relic_const_missing(*args)
    nr_check_for_constmissing("Module #{self.name} const_missing", *args)
    nr_check_for_classloading("Module #{self.name} const_missing", *args)
    non_new_relic_const_missing(*args)
  end
end

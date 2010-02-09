require File.expand_path(File.join(File.dirname(__FILE__),'..','..','test_helper'))

class ClassLoaderPatchTest < ActiveSupport::TestCase
  
  def test_const_undefined
    require 'new_relic/agent/patch_const_missing'
    ClassLoadingWatcher.background_thread = Thread.current
    
    # try loading some non-existent class
    NewRelic::Control.instance.log.expects(:error).at_least_once.with{|args| args =~ /Agent background thread.*:FooBar/}
    NewRelic::Control.instance.log.expects(:error).with{|args| args =~ /Agent background thread.*:FooBaz/}.never
    
    ClassLoadingWatcher.enable_warning
    assert_raise NameError do
      FooBar::Bat
    end
    
    ClassLoadingWatcher.disable_warning
    assert_raise NameError do
      FooBaz::Bat
    end
  end

  def test_require
    require 'new_relic/agent/patch_const_missing'
    ClassLoadingWatcher.background_thread = Thread.current
    
    # try loading some non-existent class
    NewRelic::Control.instance.log.expects(:error).at_least_once.with{|args| args =~ /Agent background thread.*rational/}
    NewRelic::Control.instance.log.expects(:error).with{|args| args =~ /Agent background thread.*pstore/}.never
    
    ClassLoadingWatcher.enable_warning
    require('rational') # standard library probably not loaded yet

    ClassLoadingWatcher.disable_warning

    require 'pstore' # standard library probably not loaded yet
  end
  
  def test_load
    require 'new_relic/agent/patch_const_missing'
    ClassLoadingWatcher.background_thread = Thread.current
    
    # try loading some non-existent class
    NewRelic::Control.instance.log.expects(:error).with{|args| args =~ /Agent background thread.*tsort/}.at_least_once
    NewRelic::Control.instance.log.expects(:error).with{|args| args =~ /Agent background thread.*getoptlong/}.never
    
    ClassLoadingWatcher.enable_warning
    
    load 'tsort.rb' # standard library probably not loaded yet

    ClassLoadingWatcher.disable_warning

    load 'getoptlong.rb'  # standard library probably not loaded yet
  end
end
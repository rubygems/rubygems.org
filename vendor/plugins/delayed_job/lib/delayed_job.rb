autoload :ActiveRecord, 'activerecord'

require File.dirname(__FILE__) + '/delayed/message_sending'
require File.dirname(__FILE__) + '/delayed/performable_method'
require File.dirname(__FILE__) + '/delayed/job'
require File.dirname(__FILE__) + '/delayed/worker'

Object.send(:include, Delayed::MessageSending)   
Module.send(:include, Delayed::MessageSending::ClassMethods)

if defined?(Merb::Plugins)
  Merb::Plugins.add_rakefiles File.dirname(__FILE__) / '..' / 'tasks' / 'tasks'
end

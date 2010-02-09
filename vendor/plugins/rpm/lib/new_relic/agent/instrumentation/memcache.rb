# NOTE there are multiple implementations of the MemCache client in Ruby,
# each with slightly different API's and semantics.  
# See:
#     http://www.deveiate.org/code/Ruby-MemCache/ (Gem: Ruby-MemCache)
#     http://dev.robotcoop.com/Libraries/memcache-client/ (Gem: memcache-client)
unless NewRelic::Control.instance['disable_memcache_instrumentation']
  MemCache.class_eval do
    add_method_tracer :get, 'MemCache/read' if self.method_defined? :get
    add_method_tracer :get_multi, 'MemCache/read' if self.method_defined? :get_multi
  %w[set add incr decr delete].each do | method |
      add_method_tracer method, 'MemCache/write' if self.method_defined? method
    end
  end if defined? MemCache 
  
  # Support for libmemcached through Evan Weaver's memcached wrapper
  # http://blog.evanweaver.com/files/doc/fauna/memcached/classes/Memcached.html    
  Memcached.class_eval do
    add_method_tracer :get, 'MemCache/read' if self.method_defined? :get
  %w[set add increment decrement delete replace append prepend cas].each do | method |
      add_method_tracer method, "MemCache/write" if self.method_defined? method
    end
  end if defined? Memcached

end

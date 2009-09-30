class ActiveRecord::Base
  def self.without_callbacks(*callbacks, &block)
    if callbacks.class == Array && (callbacks.empty? || callbacks.reject{|callback| [String,Symbol].include?(callback.class)}.empty?)
      if callbacks.empty?
        self.without_any_callbacks do
          yield
        end
      elsif
        self.without_specified_callbacks(callbacks.map(&:to_sym)) do
          yield
        end
      end
    else
      raise ArgumentError.new("Must be String, Symbol, or Array.")
    end
  end
  
  private
  
    def self.without_specified_callbacks(callbacks, &block)
      callbacks.each {|callback| raise UndefinedMethodError.new("#{self} does not define the method '#{callback}'") unless self.defines_instance_method?(callback) }
      callback_methods = callbacks.inject({}) do |hash, callback|
        hash[callback] = self.send(:instance_method, callback)
        self.send(:define_method, callback) {true}
        hash
      end
      begin
        yield
      rescue StandardError => e
        raise e
      ensure
        callback_methods.each_pair do |callback, method|
          self.send(:remove_method, callback)
          self.send(:define_method, callback, method)
        end
      end
    end
    
    def self.without_any_callbacks(&block)
      self.send(:define_method, :run_callbacks) {true}
      callbacks = ActiveRecord::Callbacks::CALLBACKS.select {|callback| self.defines_instance_method?(callback) }
      begin
        self.without_specified_callbacks(callbacks) do
          yield
        end
      rescue StandardError => e
        raise e
      ensure
        self.send(:remove_method, :run_callbacks)
      end
    end
    
    def self.defines_instance_method?(method_name)
      (self.instance_methods(false) + self.protected_instance_methods(false) + self.private_instance_methods(false)).include? method_name.to_s
    end
  
end

class UndefinedMethodError < NameError; end
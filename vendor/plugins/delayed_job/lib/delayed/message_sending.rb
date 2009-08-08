module Delayed
  module MessageSending
    def send_later(method, *args)
      Delayed::Job.enqueue Delayed::PerformableMethod.new(self, method.to_sym, args)
    end
    
    module ClassMethods
      def handle_asynchronously(method)
        without_name = "#{method}_without_send_later"
        define_method("#{method}_with_send_later") do |*args|
          send_later(without_name, *args)
        end
        alias_method_chain method, :send_later
      end
    end
  end                               
end
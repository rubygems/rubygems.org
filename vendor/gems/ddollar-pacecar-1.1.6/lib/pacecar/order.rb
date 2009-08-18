module Pacecar
  module Order
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def self.extended(base)
        base.send :define_order_scopes
      end

      protected

      def define_order_scopes
        column_names.each do |name|
          named_scope "by_#{name}".to_sym, lambda { |*args|
            { :order => "#{quoted_table_name}.#{name} #{args.flatten.first || 'asc'}" }
          }
        end
      end

    end
  end
end

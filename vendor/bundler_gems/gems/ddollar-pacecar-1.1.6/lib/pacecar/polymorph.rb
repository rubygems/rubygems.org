module Pacecar
  module Polymorph
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def has_polymorph(name)
        named_scope "for_#{name}_type".to_sym, lambda { |type|
          { :conditions => ["#{quoted_table_name}.#{name}_type = ?", type.to_s] }
        }
      end

    end
  end
end

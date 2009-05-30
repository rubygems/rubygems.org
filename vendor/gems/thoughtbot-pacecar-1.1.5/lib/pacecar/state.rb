module Pacecar
  module State
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def has_state(*names)
        opts = names.extract_options!
        names.each do |name|
          constant = opts[:with] || const_get(name.to_s.pluralize.upcase)
          constant.each do |state|
            named_scope "#{name}_#{state.downcase}".to_sym, :conditions => ["#{quoted_table_name}.#{name} = ?", state]
            named_scope "#{name}_not_#{state.downcase}".to_sym, :conditions => ["#{quoted_table_name}.#{name} <> ?", state]
            self.class_eval %Q{
              def #{name}_#{state.downcase}?
                #{name} == '#{state}'
              end
              def #{name}_not_#{state.downcase}?
                #{name} != '#{state}'
              end
            }
          end
        end
      end

    end
  end
end

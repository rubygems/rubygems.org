module Pacecar
  module Search
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def self.extended(base)
        base.send :define_search_scopes
        base.send :define_basic_search_scope
      end

      protected

      def define_search_scopes
        text_and_string_column_names.each do |name|
          named_scope "#{name}_matches".to_sym, lambda { |query|
            { :conditions => ["#{quoted_table_name}.#{name} like :query", { :query => "%#{query}%" }] }
          }
          named_scope "#{name}_starts_with".to_sym, lambda { |query|
            { :conditions => ["#{quoted_table_name}.#{name} like :query", { :query => "#{query}%" }] }
          }
          named_scope "#{name}_ends_with".to_sym, lambda { |query|
            { :conditions => ["#{quoted_table_name}.#{name} like :query", { :query => "%#{query}" }] }
          }
        end
      end

      def define_basic_search_scope
        named_scope :search_for, lambda { |*args|
          opts = args.extract_options!
          query = args.flatten.first
          columns = opts[:on] || non_state_text_and_string_columns
          joiner = opts[:require].eql?(:all) ? 'and' : 'or'
          match = columns.collect { |name| "#{quoted_table_name}.#{name} like :query" }.join(" #{joiner} ")
          { :conditions => [match, { :query => "%#{query}%" } ] }
        }
      end

    end
  end
end

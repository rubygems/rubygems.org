module Pacecar
  module Datetime
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def self.extended(base)
        base.send :define_datetime_scopes
      end

      protected

      def define_datetime_scopes
        datetime_column_names.each do |name|
          define_before_after_scopes(name)
          define_past_future_scopes(name)
          define_inside_outside_scopes(name)
          define_in_date_scopes(name)
        end
      end

      def define_before_after_scopes(name)
        named_scope "#{name}_before".to_sym, lambda { |time|
          { :conditions => ["#{quoted_table_name}.#{name} < ?", time] }
        }
        named_scope "#{name}_after".to_sym, lambda { |time|
          { :conditions => ["#{quoted_table_name}.#{name} > ?", time] }
        }
      end

      def define_past_future_scopes(name)
        named_scope "#{name}_in_past", lambda { 
          { :conditions => ["#{quoted_table_name}.#{name} < ?", Time.now] }
        }
        named_scope "#{name}_in_future", lambda {
          { :conditions => ["#{quoted_table_name}.#{name} > ?", Time.now] }
        }
      end

      def define_inside_outside_scopes(name)
        named_scope "#{name}_inside".to_sym, lambda { |start, stop|
          { :conditions => ["#{quoted_table_name}.#{name} > ? and #{quoted_table_name}.#{name} < ?", start, stop] }
        }
        named_scope "#{name}_outside".to_sym, lambda { |start, stop|
          { :conditions => ["#{quoted_table_name}.#{name} < ? and #{quoted_table_name}.#{name} > ?", start, stop] }
        }
      end

      def define_in_date_scopes(name)
        named_scope "#{name}_in_year".to_sym, lambda { |year|
          { :conditions => ["year(#{quoted_table_name}.#{name}) = ?", year] }
        }
        named_scope "#{name}_in_month".to_sym, lambda { |month|
          { :conditions => ["month(#{quoted_table_name}.#{name}) = ?", month] }
        }
        named_scope "#{name}_in_day".to_sym, lambda { |day|
          { :conditions => ["day(#{quoted_table_name}.#{name}) = ?", day] }
        }
      end

    end
  end
end

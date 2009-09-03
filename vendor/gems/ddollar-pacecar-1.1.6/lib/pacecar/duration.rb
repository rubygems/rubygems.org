module Pacecar
  module Duration
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def self.extended(base)
        base.send :define_duration_scopes
      end

      protected

      def define_duration_scopes
        named_scope :with_duration_of, lambda { |duration, start, stop|
          { :conditions => ["datediff(#{quoted_table_name}.#{start}, #{quoted_table_name}.#{stop}) = ?", duration] }
        }
        named_scope :with_duration_over, lambda { |duration, start, stop|
          { :conditions => ["datediff(#{quoted_table_name}.#{start}, #{quoted_table_name}.#{stop}) > ?", duration] }
        }
        named_scope :with_duration_under, lambda { |duration, start, stop|
          { :conditions => ["datediff(#{quoted_table_name}.#{start}, #{quoted_table_name}.#{stop}) < ?", duration] }
        }
      end

    end
  end
end

module Pacecar
  module Associations
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def has_recent_records(*names)
        names.each do |name|
          named_scope "recent_#{name}_since".to_sym, lambda { |since|
            {
              :conditions => [conditions_for_name(name), { :since_time => since }]
            }
          }
        end
        unless names.first == names.last
          named_scope "recent_#{names.join('_or_')}_since".to_sym, lambda { |since|
            {
              :conditions => [names.collect { |name| conditions_for_name(name) }.join(' or '), { :since_time => since }]
            }
          }
          named_scope "recent_#{names.join('_and_')}_since".to_sym, lambda { |since|
            {
              :conditions => [names.collect { |name| conditions_for_name(name) }.join(' and '), { :since_time => since }]
            }
          }
        end
      end

      protected

      def conditions_for_name(name)
        "((select count(*) from \"#{name}\" where \"#{name}\".#{reflections[name].primary_key_name} = #{quoted_table_name}.id and \"#{name}\".created_at > :since_time) > 0)"
      end

    end
  end
end

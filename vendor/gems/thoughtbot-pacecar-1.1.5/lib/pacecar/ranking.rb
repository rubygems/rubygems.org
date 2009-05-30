module Pacecar
  module Ranking
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def has_ranking(association)
        define_ranking_scope association, :maximum, :desc
        define_ranking_scope association, :minimum, :asc
      end

      protected

      def define_ranking_scope(association, name, direction)
        named_scope "#{name}_#{association}",
        :joins => "inner join #{association} on #{association}.#{reflections[association].primary_key_name} = #{quoted_table_name}.#{primary_key}",
        :select => "#{quoted_table_name}.*, count(#{quoted_table_name}.#{primary_key}) as #{association}_count",
        :group => "#{association}.#{reflections[association].primary_key_name}",
        :order => "#{association}_count #{direction}"
      end

    end
  end
end

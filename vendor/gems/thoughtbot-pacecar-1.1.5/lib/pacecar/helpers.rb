module Pacecar
  module Helpers

    mattr_accessor :options
    self.options = {
      :state_pattern => /_(type|state)$/i,
      :default_limit => 10
    }

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def safe_columns
        begin
          columns
        rescue ActiveRecord::StatementInvalid # If the table does not exist
          Array.new
        end
      end

      def column_names
        safe_columns.collect(&:name)
      end

      def column_names_for_type(*types)
        safe_columns.select { |column| types.include? column.type }.collect(&:name)
      end

      def column_names_without_type(*types)
        safe_columns.select { |column| ! types.include? column.type }.collect(&:name)
      end

      def boolean_column_names
        column_names_for_type :boolean
      end

      def datetime_column_names
        column_names_for_type :datetime
      end

      def text_and_string_column_names
        column_names_for_type :text, :string
      end

      def non_state_text_and_string_columns
        text_and_string_column_names.reject { |name| name =~ Pacecar::Helpers.options[:state_pattern] }
      end

    end
  end
end

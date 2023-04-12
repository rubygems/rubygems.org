class NestedValidator < ActiveRecord::Validations::AssociatedValidator
  def initialize(options)
    @with_contract = options.delete(:with_contract) { true }
    super
  end

  # def validate_each(record, attribute, value)
  #   if Array(value).reject { |r| valid_object?(r) }.any?
  #     value.errors.each do |e|
  #       record.errors.import(e, attribute: "#{attribute}.#{e.attribute}")
  #     end
  #     # record.errors.merge!(value.errors)
  #   end
  # end

  def validate_each(record, attribute, value)
    if @with_contract
      before = ActiveRecord::Type::Json.new.deserialize record.send(:"#{attribute}_before_type_cast")
      Rails.logger.warn(before:, as_json: before.as_json)
      value.class::Contract.new.call(before.as_json.deep_symbolize_keys).errors(full: true).each do |error|
        attr = error.path.map { |e| e.is_a?(Symbol) ? ".#{e}" : "[#{e}]" }.join.delete_prefix(".")
        if error.respond_to?(:text)
          value.errors.add(attr, error.text)
        elsif error.respond_to?(:messages)
          # error.messages.each { value.errors.add(attr, _1.pretty_inspect) }
          value.errors.add(attr, error.pretty_inspect)
        else
          value.errors.add(attr, error.to_s)
        end
      end
      value.errors.each do |e|
        record.errors.import(e, attribute: "#{attribute}.#{e.attribute}")
      end
    elsif Array(value).reject { |r| valid_object?(r) }.any?
      value.errors.each do |e|
        record.errors.import(e, attribute: "#{attribute}.#{e.attribute}")
      end
      # record.errors.merge!(value.errors)
    end
  end
end

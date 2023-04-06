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
      before = record.send(:"#{attribute}_before_type_cast")
      errors = ActiveModel::Errors.new(before)
      value.class::Contract.new.call(before).errors.each do |e|
        errors.add(e.path.map { |e| e.is_a?(Symbol) ? ".#{e}" : "[#{e}]" }.join.delete_prefix("."), e.text)
      end
      errors.each do |e|
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

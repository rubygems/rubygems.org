class NestedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    case value
    when Array
      value.each_with_index do |v, i|
        next if v.valid?
        v.errors.each do |e|
          record.errors.import(e, attribute: "#{attribute}[#{i}].#{e.attribute}")
        end
      end
    else
      if Array(value).reject { _1.valid? }.any?
        value.errors.each do |e|
          record.errors.import(e, attribute: "#{attribute}.#{e.attribute}")
        end
      end
    end
  end
end

module Events::Tag
  module_function

  def additional_name(tag)
    parts = tag.split(":")
    parts.shift
    :"#{parts.join('_').classify}Additional"
  end

  def const_name(tag)
    parts = tag.split(":")
    parts.shift
    parts.map!(&:classify).join("::")
  end

  def translation_key(tag)
    source, subject, *rest = tag.split(":")
    return "events.#{source}_event.#{source}.#{subject}" if rest.empty?
    "events.#{source}_event.#{subject}.#{subject}_#{rest.join('_')}"
  end
end

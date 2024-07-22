module DurationHelper
  def duration_string(duration)
    parts = duration.parts
    parts = { seconds: duration.value } if parts.empty?

    to_sentence(parts
      .sort_by { |unit, _| ActiveSupport::Duration::PARTS.index(unit) }
      .map     { |unit, val| t("duration.#{unit}", count: val) })
  end
end

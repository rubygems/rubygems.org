# frozen_string_literal: true

# Rejects a gem name that falls under a prefix an organization has reserved,
# unless that organization is the one claiming the name.
#
# Rubygem applies this only when the name is being claimed -- a brand new gem or
# a rename -- so a gem that predates the reservation keeps pushing new versions
# of its own name.
class ReservedPrefixValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    reservation = PrefixReservation.covering(value).first
    return if reservation.nil? || reservation.permitted?(record)

    record.errors.add(attribute, reservation.conflict_message(value))
  end
end

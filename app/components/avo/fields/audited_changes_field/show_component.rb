# frozen_string_literal: true

class Avo::Fields::AuditedChangesField::ShowComponent < Avo::Fields::ShowComponent
  def records
    field.value["records"]&.map do |gid, body|
      changes, unchanged = body.values_at("changes", "unchanged")

      [gid, changes, unchanged]
    end
  end
end

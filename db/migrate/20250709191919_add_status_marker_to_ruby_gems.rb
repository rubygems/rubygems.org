class AddStatusMarkerToRubyGems < ActiveRecord::Migration[8.0]
  def change
    create_enum :status_marker, %w[active archived quarantined deprecated]
    add_column :rubygems, :status_marker, :enum, enum_type: :status_marker, default: :active
  end
end

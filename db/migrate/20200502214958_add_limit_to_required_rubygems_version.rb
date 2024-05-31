class AddLimitToRequiredRubygemsVersion < ActiveRecord::Migration[6.0]
  def change
    change_column :versions, :required_rubygems_version, :string, limit: Gemcutter::MAX_FIELD_LENGTH # rubocop:disable Rails/ReversibleMigration
  end
end

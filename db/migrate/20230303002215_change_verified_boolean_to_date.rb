class ChangeVerifiedBooleanToDate < ActiveRecord::Migration[7.0]
  def change
    %w{home code docs wiki mail bugs}.each do |name|
      remove_column(:linksets, "#{name}_verified", :boolean)
      add_column :linksets, "#{name}_verified_at", :date
    end
  end
end

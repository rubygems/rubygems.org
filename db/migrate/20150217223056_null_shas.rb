class NullShas < ActiveRecord::Migration
  def change
    change_column_null(:versions, :sha256, false)
  end
end

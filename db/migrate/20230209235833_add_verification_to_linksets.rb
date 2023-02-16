class AddVerificationToLinksets < ActiveRecord::Migration[7.0]
  def change
    %w{home code docs wiki mail bugs}.each do |name|
      add_column :linksets, "#{name}_verified", :boolean
    end
  end
end

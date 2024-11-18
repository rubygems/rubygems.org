class ValidateAddOrganizationForeignKeytoRubyGems < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key :rubygems, :organizations
  end
end

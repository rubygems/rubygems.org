class CreateVulnerabilities < ActiveRecord::Migration[7.0]
  def change
    create_table :vulnerabilities do |t|
      t.string :identifier
      t.string :url
      t.string :level
      t.string :title
    end
  end
end

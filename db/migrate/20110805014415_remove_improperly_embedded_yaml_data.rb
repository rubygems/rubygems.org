class RemoveImproperlyEmbeddedYamlData < ActiveRecord::Migration[4.2]
  def self.up
    # Dependency.where("requirements like '%YAML::Syck::DefaultKey%'").find_each do |d|
    #   d.requirements = d.clean_requirements
    #   d.save(validate: false)
    # end
  end

  def self.down
    # Do nothing.
  end
end

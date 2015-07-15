class RemoveImproperlyEmbeddedYamlData < ActiveRecord::Migration
  def self.up
    Dependency.where("requirements like '%YAML::Syck::DefaultKey%'").each do |d|
      d.requirements = d.clean_requirements
      d.save(validate: false)
    end
  end

  def self.down
    # Do nothing.
  end
end

class ModelGenerator < Rails::Generator::NamedBase
  default_options :skip_timestamps => false, 
                  :skip_migration  => false, 
                  :skip_factories  => false

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions class_name, "#{class_name}Test"

      # Model, test, and factories directories.
      m.directory File.join('app/models',     class_path)
      m.directory File.join('test/unit',      class_path)
      m.directory File.join('test/factories', class_path)

      # Model class, unit test, and factories.
      m.template 'model.rb',      File.join('app/models', class_path, 
                                            "#{file_name}.rb")
      m.template 'unit_test.rb',  File.join('test/unit', class_path, 
                                            "#{file_name}_test.rb")

      m.template 'factory.rb',  File.join('test/factories', "#{file_name}.rb")

      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate', :assigns => {
          :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}"
        }, :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
      end
    end
  end

  def factory_line(attribute, file_name)
    if attribute.reference?
      "#{file_name}.association(:#{attribute.name})"
    else
      "#{file_name}.#{attribute.name} #{attribute.default_for_factory}"
    end
  end

  protected

    def banner
      "Usage: #{$0} #{spec.name} ModelName [field:type, field:type]"
    end

    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("--skip-timestamps",
             "Don't add timestamps to the migration file for this model") { |v| 
        options[:skip_timestamps] = v 
      }
      opt.on("--skip-migration", 
             "Don't generate a migration file for this model") { |v| 
        options[:skip_migration] = v 
      }
    end
end

module Rails
  module Generator
    class GeneratedAttribute
      def default_for_factory
        @default ||= case type
          when :integer                     then "{ 1 }"
          when :float                       then "{ 1.5 }"
          when :decimal                     then "{ 9.99 }"
          when :datetime, :timestamp, :time then "{ Time.now.to_s(:db) }"
          when :date                        then "{ Date.today.to_s(:db) }"
          when :string                      then "{ 'string' }"
          when :text                        then "{ 'text' }"
          when :boolean                     then "{ false }"
          else
            ""
        end
      end
    end
  end
end

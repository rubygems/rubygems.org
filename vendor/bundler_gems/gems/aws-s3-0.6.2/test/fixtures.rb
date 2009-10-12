require 'yaml'

module AWS
  module S3
    # When this file is loaded, for each fixture file, a module is created within the Fixtures module
    # with the same name as the fixture file. For each fixture in that fixture file, a singleton method is 
    # added to the module with the name of the given fixture, returning the value of the fixture.
    #
    # For example:
    #
    # A fixture in <tt>buckets.yml</tt> named <tt>empty_bucket_list</tt> with value <tt><foo>hi!</foo></tt>
    # would be made available like so:
    #
    #   Fixtures::Buckets.empty_bucket_list
    #   => "<foo>hi!</foo>"
    #   
    # Alternatively you can treat the fixture module like a hash
    #
    #   Fixtures::Buckets[:empty_bucket_list]
    #   => "<foo>hi!</foo>"
    #
    # You can find out all available fixtures by calling
    #
    #   Fixtures.fixtures
    #   => ["Buckets"]
    #
    # And all the fixtures contained in a given fixture by calling
    #
    #   Fixtures::Buckets.fixtures
    #   => ["bucket_list_with_more_than_one_bucket", "bucket_list_with_one_bucket", "empty_bucket_list"]
    module Fixtures
      class << self
        def create_fixtures
          files.each do |file|
            create_fixture_for(file)
          end
        end
        
        def create_fixture_for(file)
          fixtures       = YAML.load_file(path(file))
          fixture_module = Module.new
          
          fixtures.each do |name, value|
            fixture_module.module_eval(<<-EVAL, __FILE__, __LINE__)
              def #{name}
                #{value.inspect}
              end
              module_function :#{name}
            EVAL
          end
          
          fixture_module.module_eval(<<-EVAL, __FILE__, __LINE__)
            module_function 
          
              def fixtures
                #{fixtures.keys.sort.inspect}
              end
              
              def [](name)
                send(name) if fixtures.include?(name.to_s)
              end
          EVAL
          
          const_set(module_name(file), fixture_module)
        end
        
        def fixtures
          constants.sort
        end
        
        private
        
          def files
            Dir.glob(File.dirname(__FILE__) + '/fixtures/*.yml').map {|fixture| File.basename(fixture)}
          end
          
          def module_name(file_name)
            File.basename(file_name, '.*').capitalize
          end
          
          def path(file_name)
            File.join(File.dirname(__FILE__), 'fixtures', file_name)
          end
      end
      
      create_fixtures
    end
  end
end
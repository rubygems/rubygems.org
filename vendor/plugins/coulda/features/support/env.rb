require 'test/unit'

module Test::Unit::Assertions

  def assert_generated_controller_for(name)
    assert_generated_file "app/controllers/#{name}_controller.rb" do |body|
      yield body if block_given?
    end
  end

  def assert_generated_model_for(name)
    assert_generated_file "app/models/#{name}.rb" do |body|
      yield body if block_given?
    end
  end

  def assert_generated_helper_for(name)
    assert_generated_file "app/helpers/#{name}_helper.rb" do |body|
      yield body if block_given?
    end
  end

  def assert_generated_factory_for(name)
    assert_generated_file "test/factories/#{name}.rb" do |body|
      yield body if block_given?
    end
  end

  def assert_generated_functional_test_for(name)
    assert_generated_file "test/functional/#{name}_controller_test.rb" do |body|
      yield body if block_given?
    end
  end

  def assert_generated_unit_test_for(name)
    assert_generated_file "test/unit/#{name}_test.rb" do |body|
      yield body if block_given?
    end
  end

  def assert_generated_helper_test_for(name)
    assert_generated_file "test/unit/helpers/#{name}_helper_test.rb" do |body|
      yield body if block_given?
    end
  end

  def assert_generated_file(path)
    assert_file_exists(path)
    File.open(File.join(@rails_root, path)) do |file|
      yield file.read if block_given?
    end
  end

  def assert_file_exists(path)
    file = File.join(@rails_root, path)

    assert File.exists?(file), "#{file} expected to exist, but did not"
    assert File.file?(file),   "#{file} expected to be a file, but is not"
  end

  def assert_generated_views_for(name, *actions)
    actions.each do |action|
      assert_generated_file("app/views/#{name}/#{action}.html.erb") do |body|
        yield body if block_given?
      end
    end
  end

  def assert_generated_migration(name)
    file = Dir.glob("#{@rails_root}/db/migrate/*_#{name}.rb").first
    file = file.match(/db\/migrate\/[0-9]+_\w+/).to_s << ".rb"
    assert_generated_file file do |body|
      assert_match /timestamps/, body, "should have timestamps defined"
      yield body if block_given?
    end
  end

  def assert_generated_route_for(name)
    assert_generated_file("config/routes.rb") do |body|
      assert_match /map.resources :#{name.to_s.underscore}/, body,
        "should add route for :#{name.to_s.underscore}"
    end
  end

  def assert_has_empty_method(body, *methods)
    methods.each do |name|
      assert body.include?("  def #{name}\n  end"), 
        "should have method #{name} in #{body.inspect}"
      yield(name, $2) if block_given?
    end
  end

end

World do |world|
  world.extend(Test::Unit::Assertions)
  world
end


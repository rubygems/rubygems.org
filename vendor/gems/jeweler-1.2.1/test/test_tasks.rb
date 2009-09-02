require 'test_helper'

require 'rake'
class TestTasks < Test::Unit::TestCase
  include Rake

  context 'instantiating Jeweler::Tasks' do
    setup do
      @jt = Jeweler::Tasks.new {}
    end

    teardown do
      Task.clear
    end

    should 'assign @gemspec' do
      assert_not_nil @jt.gemspec
    end

    should 'assign @jeweler' do
      assert_not_nil @jt.jeweler
    end

    should 'yield the gemspec instance' do
      spec = nil; Jeweler::Tasks.new { |s| spec = s }
      assert_not_nil spec
    end

    should 'set the gemspec defaults before yielding it' do
      Jeweler::Tasks.new do |s|
        assert !s.files.empty?
      end
    end
  end
end

require 'test_helper'

class RubygemFsTest < ActiveSupport::TestCase
  context "local filesystem" do
    setup do
      @fs = RubygemFs::Local.new
      def @fs.base_dir
        @dir ||= Dir.mktmpdir
      end
    end

    context "#get" do
      should "return nil when file doesnt exist" do
        assert_nil @fs.get 'foo'
      end

      should "return get the file" do
        @fs.store 'foo', 123
        assert_equal "123", @fs.get('foo')
      end
    end

    context "#store" do
      should "store the file" do
        assert @fs.store 'foo', "hello w."
        assert_equal "hello w.", @fs.get('foo')
      end

      should "create the necessary sub-folders to store" do
        assert @fs.store 'gems/foo.gem', "hello w."
        assert_equal "hello w.", @fs.get('gems/foo.gem')
      end
    end

    context "#remove" do
      setup do
        @fs.store 'foo', 123
      end

      should "remove the file" do
        assert @fs.remove 'foo'
      end

      should "return false when file doesnt exist" do
        refute @fs.remove 'bar'
      end
    end
  end
end

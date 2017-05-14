require 'test_helper'

class RubygemFsTest < ActiveSupport::TestCase
  context "s3 filesystem" do
    should "use default bucket when not passing as an argument" do
      fs = RubygemFs::S3.new
      assert_equal "test.s3.rubygems.org", fs.bucket
    end

    should "use bucket passed" do
      fs = RubygemFs::S3.new(bucket: "foo.com")
      assert_equal "foo.com", fs.bucket
    end

    should "use a custom config when passed" do
      fs = RubygemFs::S3.new(access_key_id: 'foo', secret_access_key: 'bar')
      def fs.s3
        [@config[:access_key_id], @config[:secret_access_key]]
      end
      assert_equal %w[foo bar], fs.s3
    end
  end

  context "local filesystem" do
    setup do
      @fs = RubygemFs::Local.new(Dir.mktmpdir)
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

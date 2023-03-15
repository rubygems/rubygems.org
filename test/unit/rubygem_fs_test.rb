require "test_helper"

class RubygemFsTest < ActiveSupport::TestCase
  context "s3 filesystem" do
    setup do
      @fs = RubygemFs::S3.new
      @s3 = Aws::S3::Client.new(stub_responses: true)
      @fs.instance_variable_set(:@s3, @s3)
    end

    should "use default bucket when not passing as an argument" do
      fs = RubygemFs::S3.new

      assert_equal "test.s3.rubygems.org", fs.bucket
    end

    should "use bucket passed" do
      fs = RubygemFs::S3.new(bucket: "foo.com")

      assert_equal "foo.com", fs.bucket
    end

    should "use a custom config when passed" do
      fs = RubygemFs::S3.new(access_key_id: "foo", secret_access_key: "bar")
      def fs.s3_config
        [@config[:access_key_id], @config[:secret_access_key]]
      end

      assert_equal %w[foo bar], fs.s3_config
    end

    context "#store" do
      should "store the file in the bucket" do
        bucket = key = body = nil
        @s3.stub_responses(:put_object, lambda { |context|
          bucket, key, body = context.params.values_at(:bucket, :key, :body)
          {}
        })

        assert @fs.store("foo", "hello world")
        assert_equal "foo", key
        assert_equal "hello world", body
        assert_equal "test.s3.rubygems.org", bucket
      end
    end

    context "#get" do
      should "return nil when file doesnt exist" do
        @s3.stub_responses(:get_object, ->(_) { "NoSuchKey" })

        assert_nil @fs.get("foo")
        assert_nil @fs.get("foo/bar/baz")
      end

      should "return the file" do
        @s3.stub_responses(:get_object, ->(_) { { body: "123" } })

        assert_equal "123", @fs.get("foo")
      end
    end

    context "#each_key" do
      should "lists keys without prefix" do
        @s3.stub_responses(:list_objects_v2, ->(_) { { contents: [{ key: "foo" }, { key: "bar" }] } })

        keys = []
        @fs.each_key { |key| keys << key }

        assert_equal %w[bar foo], keys.sort
      end

      should "lists keys with prefix" do
        prefix = nil
        @s3.stub_responses(:list_objects_v2, lambda { |context|
          prefix = context.params[:prefix]
          { contents: [{ key: "bar" }, { key: "baz" }], prefix: prefix }
        })

        assert_equal %w[bar baz], @fs.each_key(prefix: "ba").sort
        assert_equal "ba", prefix
      end
    end

    context "#remove" do
      should "removes a single file that exists" do
        keys = nil
        @s3.stub_responses(:delete_objects, lambda { |context|
          keys = context.params[:delete][:objects].pluck(:key)
          {}
        })

        assert_empty @fs.remove("foo")
        assert_equal ["foo"], keys
      end

      should "removes files that exists" do
        keys = nil
        @s3.stub_responses(:delete_objects, lambda { |context|
          keys = context.params[:delete][:objects].pluck(:key)
          {}
        })

        assert_empty @fs.remove(%w[foo bar])
        assert_equal %w[foo bar], keys
      end

      should "returns keys for which delete did not work" do
        @s3.stub_responses(:delete_objects, lambda { |_|
          { errors: [{ key: "missing" }] }
        })

        assert_equal ["missing"], @fs.remove(%w[foo missing])
      end
    end
  end

  context "local filesystem" do
    setup do
      @fs = RubygemFs::Local.new(Dir.mktmpdir)
    end

    context "#initialize" do
      should "convert the path to an absolute path" do
        fs = RubygemFs::Local.new("dir")

        assert_equal File.expand_path("dir"), fs.base_dir.to_s
      end

      should "default to RAILS_ROOT/server" do
        fs = RubygemFs::Local.new

        assert_equal Rails.root.join("server"), fs.base_dir
      end
    end

    context "#get" do
      should "return nil when file doesnt exist" do
        assert_nil @fs.get "foo"
      end

      should "get the file" do
        @fs.store "foo", "123"

        assert_equal "123", @fs.get("foo")
      end
    end

    context "#store" do
      should "store the file" do
        assert @fs.store "foo", "hello w."
        assert_equal "hello w.", @fs.get("foo")
      end

      should "create the necessary sub-folders to store" do
        assert @fs.store "gems/foo.gem", "hello w."
        assert_equal "hello w.", @fs.get("gems/foo.gem")
      end

      should "ignore leading slashes on key names" do
        assert @fs.store "/latest_specs.4.8.gz", "" # example from hostess_test.rb
        assert_equal "", @fs.get("/latest_specs.4.8.gz")
      end

      should "work with metadata keyword arguments (even if they are currently ignored)" do
        assert @fs.store "content/file", "info", metadata: { "foo" => "bar" }, content_type: "text/plain"
        assert_equal "info", @fs.get("content/file")
      end
    end

    context "#each_key" do
      setup do
        @fs.store "foo", ""
        @fs.store "bar/foo", ""
        @fs.store "bar/baz/foo", ""
        @fs.store "barbeque", ""
        @fs.store "baz", ""
        @fs.store ".hidden", ""
      end

      should "yield all keys when a block is given" do
        keys = []
        @fs.each_key { |key| keys << key }

        assert_equal %w[.hidden bar/baz/foo bar/foo barbeque baz foo], keys.sort
      end

      should "return an enumerable when no block is given" do
        assert_equal %w[.hidden bar/baz/foo bar/foo barbeque baz foo], @fs.each_key.sort
      end

      should "list all keys with prefix" do
        assert_equal %w[bar/baz/foo bar/foo], @fs.each_key(prefix: "bar/").sort
        assert_equal %w[bar/baz/foo bar/foo barbeque], @fs.each_key(prefix: "bar").sort
      end

      should "list all keys with partial prefix like S3 (unlike normal file systems)" do
        assert_equal %w[bar/baz/foo bar/foo barbeque baz], @fs.each_key(prefix: "ba").sort
      end
    end

    context "#remove" do
      setup do
        @fs.store "foo", "123"
      end

      should "remove the file" do
        assert_empty @fs.remove("foo")
      end

      should "return failing key when file doesnt exist" do
        assert_equal ["bar"], @fs.remove("bar")
      end

      should "not remove anything that causes problems on the filesystem" do
        assert_equal [""], @fs.remove("")
        assert_equal ["."], @fs.remove(".")
        assert_equal [".."], @fs.remove("..")
        assert_equal ["/"], @fs.remove("/")
      end

      should "remove empty base folders when removing nested key" do
        @fs.store "bar/baz/foo/file", "123"
        @fs.store "bar/directory_not_empty", "don't remove me"

        assert_raise(Errno::EISDIR) do
          # s3 imitiation limitiation is files overlapping dirs
          @fs.store "bar/baz", "this is a directory!"
        end

        assert_empty @fs.remove("bar/baz/foo/file")

        @fs.store "bar/baz", "not a directory anymore"

        assert_equal "don't remove me", @fs.get("bar/directory_not_empty")
      end

      should "removes multiple files" do
        @fs.store "bar", "123"
        @fs.store "baz", "123"

        assert_empty @fs.remove("foo", "bar")
        refute @fs.get("foo")
        refute @fs.get("bar")
        assert @fs.get("baz")
      end

      should "returns a list of errors on partial failure" do
        assert_equal ["baz"], @fs.remove(%w[foo baz])
        refute @fs.get("foo")
      end
    end
  end
end

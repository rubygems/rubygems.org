# frozen_string_literal: true

require "test_helper"

class RubygemFsTest < ActiveSupport::TestCase
  context "#instance" do
    setup do
      RubygemFs.instance_variable_set(:@fs, nil)
    end

    teardown do
      RubygemFs.mock!
    end

    should "return S3 by default in Production" do
      ENV["RAILS_ENV"] = "production"

      assert_kind_of RubygemFs::S3, RubygemFs.instance
    ensure
      ENV["RAILS_ENV"] = "test"
    end

    should "return the default bucket instance" do
      assert_equal Gemcutter.config.s3_bucket, RubygemFs.instance.bucket
    end

    should "return the contents bucket instance" do
      assert_equal Gemcutter.config.s3_contents_bucket, RubygemFs.contents.bucket
    end

    should "return the same instance each time" do
      assert_equal RubygemFs.instance, RubygemFs.instance
      assert_equal RubygemFs.contents, RubygemFs.contents
    end
  end

  context "#mock!" do
    should "set instance to a Local mock" do
      assert_kind_of RubygemFs::Local, RubygemFs.mock!
    end

    should "return mock for contents as well" do
      RubygemFs.mock!

      assert_kind_of RubygemFs::Local, RubygemFs.contents
    end
  end

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

    context "#in_bucket" do
      should "return a new instance with the bucket set" do
        foo_fs = @fs.in_bucket("foo.com")

        refute_equal @fs, foo_fs
        assert_equal "foo.com", foo_fs.bucket
      end
    end

    context "#bucket" do
      should "return the S3 bucket" do
        assert_equal Gemcutter.config.s3_bucket, @fs.bucket
      end
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

    context "#head" do
      should "return nil when file doesnt exist" do
        @s3.stub_responses(:head_object, ->(_) { "NoSuchKey" })

        assert_nil @fs.head("foo")
        assert_nil @fs.head("foo/bar/baz")
      end

      should "return s3 response Hash" do
        metadata = { "size" => "123", "path" => "foo" }
        @s3.stub_responses(:head_object, ->(_) { { content_type: "text/plain", metadata: metadata } })

        response = @fs.head("paths/foo")

        assert_equal "text/plain", response[:content_type]
        assert_equal metadata, response[:metadata]
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

      should "list keys with a delimiter" do
        delimiter = nil
        @s3.stub_responses(:list_objects_v2, lambda { |context|
          delimiter = context.params[:delimiter]
          { contents: [{ key: "bar" }, { key: "baz" }], common_prefixes: [{ prefix: "blah/" }, { prefix: "foo/" }], delimiter: delimiter }
        })

        assert_equal %w[blah/ foo/ bar baz], @fs.each_key(delimiter: "/").to_a
        assert_equal "/", delimiter
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
        assert_equal "server", fs.bucket
      end
    end

    context "#in_bucket" do
      should "return a new instance with the bucket set" do
        foo_fs = @fs.in_bucket "dir"

        refute_equal @fs, foo_fs
        assert_equal "dir", foo_fs.bucket
      end
    end

    context "#bucket" do
      should "return the basename of the base_dir to imitate S3" do
        fs = @fs.in_bucket "dir"

        assert_equal "dir", fs.bucket
      end
    end

    context "#get" do
      should "return nil when file doesnt exist" do
        assert_nil @fs.get "missing"
      end

      should "return nil when the file requested is a directory" do
        @fs.store "dir/foo", "123"

        assert_nil @fs.get "dir"
      end

      should "get the file" do
        @fs.store "foo", "123"

        assert_equal "123", @fs.get("foo")
      end

      should "get a binary file lacking metadata" do
        gem_data = gem_file.read
        @fs.store "gems/test.gem", gem_data

        assert_equal gem_data, @fs.get("gems/test.gem")
        assert_equal Encoding::BINARY, @fs.get("gems/test.gem").encoding
      end

      should "should discover encoding using Magic when the file has incomplete content type without charset" do
        body = "emoji 😁"
        @fs.store "file", body, content_type: "text/plain"

        assert_equal body, @fs.get("file")
        assert_equal Encoding::UTF_8, @fs.get("file").encoding
      end
    end

    context "#head" do
      should "return nil when file doesnt exist" do
        assert_nil @fs.head "missing"
      end

      should "return nil when the file requested is a directory" do
        @fs.store "dir/foo", "123"

        assert_nil @fs.head "dir"
      end

      should "return blank metadata for a file stored without any metadata" do
        @fs.store "nometadata", "123"
        response = @fs.head "nometadata"

        assert_equal "nometadata", response[:key]
        assert_empty response[:metadata]
      end

      should "return metadata for a file stored with metadata" do
        @fs.store "foo", "123", metadata: { "foo" => "bar" }
        response = @fs.head "foo"

        assert_equal "foo", response[:key]
        assert_equal "bar", response[:metadata]["foo"]
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

      should "work with metadata keyword arguments" do
        assert @fs.store "with/metadata", "info", metadata: { "foo" => "bar" }, content_type: "text/plain"

        assert_equal "info", @fs.get("with/metadata")

        response = @fs.head("with/metadata")

        assert_equal "with/metadata", response[:key]
        assert_equal "text/plain", response[:content_type]
        assert_equal({ "foo" => "bar" }, response[:metadata])
      end
    end

    context "#each_key" do
      setup do
        @fs.store "foo", ""
        @fs.store "bar/foo", ""
        @fs.store "bar/baz/foo", ""
        @fs.store "barbeque", ""
        @fs.store "baz", ""
        @fs.store ".hidden", "", metadata: { "foo" => "bar" } # ensure _metadata is not returned
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
      end

      should "raise InvalidPathError for prefix not ending in /" do
        assert_raises(RubygemFs::Local::InvalidPathError) { @fs.each_key(prefix: "bar").to_a }
      end

      should "list keys with a delimiter" do
        assert_equal %w[bar/ .hidden barbeque baz foo], @fs.each_key(delimiter: "/").to_a
      end

      should "list keys with a prefix and delimiter" do
        assert_equal %w[bar/baz/ bar/foo], @fs.each_key(prefix: "bar/", delimiter: "/").to_a
      end

      should "raise ArgumentError when prefix doesn't end in /" do
        assert_raises(ArgumentError) { @fs.each_key(prefix: "bar", delimiter: "/").to_a }
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
        assert_raise(RubygemFs::Local::InvalidPathError, "blank key") { @fs.remove("") }
        assert_raise(RubygemFs::Local::InvalidPathError, "root") { @fs.remove("/") }
        assert_raise(RubygemFs::Local::InvalidPathError, "pwd") { @fs.remove(".") }
        assert_raise(RubygemFs::Local::InvalidPathError, "parent dir") { @fs.remove("..") }
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

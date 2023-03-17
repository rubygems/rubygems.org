require "test_helper"

class RubygemContentsTest < ActiveSupport::TestCase
  def create_entry(body, mime: "text/plain", sha256: nil)
    sha256 ||= Digest::SHA256.hexdigest(body) if body
    GemContentEntry.new(path: "file", size: body.bytesize, body: body, mime: mime, sha256: sha256)
  end

  setup do
    RubygemFs.mock!
    @rubygem_contents = RubygemContents.new(gem: "gemname")
    @entry = create_entry("body")
  end

  teardown do
    RubygemFs.mock!
  end

  context "#root" do
    should "return a path" do
      assert_equal "gems/gemname/contents/", @rubygem_contents.root
    end
  end

  context "#key" do
    should "return a path" do
      assert_equal "gems/gemname/contents/abcbeefdad1234", @rubygem_contents.key("abcbeefdad1234")
    end
  end

  context "#store" do
    should "not store content when not body is not persisted" do
      entry = create_entry("binary", mime: "application/octet-stream")

      refute_predicate entry, :body_persisted?
      refute @rubygem_contents.store(entry)
      assert_nil @rubygem_contents.get(entry.fingerprint)
    end

    should "store content at a key" do
      assert @rubygem_contents.store(@entry)
      key = @rubygem_contents.key(@entry.fingerprint)
      head = @rubygem_contents.fs.head(key)

      assert_equal @entry.body, @rubygem_contents.get(@entry.fingerprint)
      assert_equal @entry.body, @rubygem_contents.fs.get(key)
      assert_equal @entry.mime, head[:content_type]
      assert_equal @entry.size, head[:content_length]
      assert_equal @entry.sha256, head[:checksum_sha256]
    end
  end

  context "#get" do
    should "return nil for a blank hex" do
      assert_nil @rubygem_contents.get("")
      assert_nil @rubygem_contents.get(nil)
    end

    should "return nil for a non-indexed file" do
      assert_nil @rubygem_contents.get("NotFoundDigest")
    end

    should "retrieve stored content" do
      @rubygem_contents.store(@entry)

      assert_equal @entry.body, @rubygem_contents.get(@entry.fingerprint)
    end
  end

  context "#keys" do
    should "return an empty list for a new index" do
      assert_empty @rubygem_contents.keys
    end

    should "return a list of content keys" do
      @entry2 = create_entry("body2")
      @rubygem_contents.store(@entry)
      @rubygem_contents.store(@entry2)

      assert_equal [@entry.fingerprint, @entry2.fingerprint].sort, @rubygem_contents.keys.sort
    end
  end

  context "#==" do
    should "return true for the same gem" do
      assert_equal @rubygem_contents, RubygemContents.new(gem: "gemname")
    end

    should "return false for a different gem" do
      refute_equal @rubygem_contents, RubygemContents.new(gem: "other")
    end
  end
end

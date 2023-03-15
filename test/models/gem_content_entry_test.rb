require "test_helper"

class GemContentEntryTest < ActiveSupport::TestCase
  setup do
    @binary_io = gem_file
  end

  teardown do
    @binary_io.close
  end

  def binary_data
    @binary_data ||= @binary_io.read
  end

  def create_entry(path: "lib/foo.rb", size: nil, file_mode: 0o644, linkname: "", body: "body")
    GemContentEntry.from_tar_entry(
      stub(
        full_name: path,
        header: stub(mode: file_mode, linkname: linkname),
        read: body,
        size: size || body&.bytesize || 0,
        symlink?: linkname.present?
      )
    )
  end

  def create_persisted_entry(metadata, &)
    GemContentEntry.from_metadata(metadata.stringify_keys, &)
  end

  def file_entry
    @file_entry ||= create_entry(
      path: "lib/foo.rb",
      body: "file body\nwith snowman emoji\n⛄️\n"
    )
  end

  def empty_entry
    @empty_entry ||= create_entry(
      path: "lib/empty.rb",
      body: ""
    )
  end

  def large_entry
    tar_entry = stub(
      full_name: "lib/large.rb",
      header: stub(mode: 0o644, linkname: ""),
      size: GemContentEntry::SIZE_LIMIT + 1,
      symlink?: false
    )
    tar_entry.stubs(:read).with(4096).returns("a" * 4096)
    GemContentEntry.from_tar_entry(tar_entry)
  end

  def binary_entry
    @binary_entry ||= create_entry(
      path: "exe/binary",
      body: binary_data,
      file_mode: 0o755
    )
  end

  def symlink_entry
    @symlink_entry ||= create_entry(
      path: "lib/link.rb",
      file_mode: 0o20644,
      linkname: "target.rb",
      body: ""
    )
  end

  def persisted_file_entry
    @persisted_file_entry ||= create_persisted_entry(file_entry.metadata) { file_entry.body }
  end

  def persisted_empty_entry
    @persisted_empty_entry ||= create_persisted_entry(empty_entry.metadata) { "" }
  end

  def persisted_large_entry
    @persisted_large_entry ||= create_persisted_entry(large_entry.metadata) { nil }
  end

  def persisted_binary_entry
    @persisted_binary_entry ||= create_persisted_entry(binary_entry.metadata) { binary_entry.body }
  end

  def persisted_symlink_entry
    @persisted_symlink_entry ||= create_persisted_entry(symlink_entry.metadata) { nil }
  end

  context ".from_tar_entry" do
    should "return a file entry" do
      tar_entry = mock("tar_entry")
      tar_entry.expects(:full_name).returns(file_entry.path)
      tar_entry.expects(:header).at_least_once.returns(mock(mode: 0o644))
      tar_entry.expects(:size).at_least_once.returns(file_entry.size)
      tar_entry.expects(:symlink?).returns(false)
      tar_entry.expects(:read).returns(file_entry.body)
      entry = GemContentEntry.from_tar_entry(tar_entry)

      assert_equal file_entry, entry
      assert_predicate entry, :file?
    end

    should "return an empty file entry" do
      tar_entry = mock("tar_entry")
      tar_entry.expects(:full_name).returns(empty_entry.path)
      tar_entry.expects(:header).at_least_once.returns(mock(mode: 0o644))
      tar_entry.expects(:size).at_least_once.returns(0)
      tar_entry.expects(:symlink?).returns(false)
      tar_entry.expects(:read).returns("")
      entry = GemContentEntry.from_tar_entry(tar_entry)

      assert_equal empty_entry, entry
      assert_predicate entry, :file?
    end

    should "not fully read an entry that is too large" do
      tar_entry = mock("tar_entry")
      tar_entry.expects(:full_name).returns(large_entry.path)
      tar_entry.expects(:header).returns(mock(mode: 0o644))
      tar_entry.expects(:size).at_least_once.returns(GemContentEntry::SIZE_LIMIT + 1)
      tar_entry.expects(:symlink?).returns(false)
      tar_entry.expects(:read).with(4096).returns("a" * 4096)
      entry = GemContentEntry.from_tar_entry(tar_entry)

      assert_equal large_entry, entry
      refute_predicate entry, :body_persisted?
      assert_nil entry.body
      assert_predicate entry, :file?
      assert_predicate entry, :large?
    end

    should "return a symlink entry" do
      tar_entry = mock("tar_entry")
      tar_entry.expects(:full_name).returns(symlink_entry.path)
      tar_entry.expects(:header).at_least_once.returns(mock(mode: 0o20644, linkname: symlink_entry.linkname))
      tar_entry.expects(:size).at_least_once.returns(0)
      tar_entry.expects(:symlink?).returns(true)
      entry = GemContentEntry.from_tar_entry(tar_entry)

      assert_equal symlink_entry, entry
      assert_predicate entry, :symlink?
    end
  end

  context ".from_metadata" do
    should "raise InvalidMetadata if the metadata lacks required keys" do
      assert_raises(GemContentEntry::InvalidMetadata) { GemContentEntry.from_metadata({}) }
      assert_raises(GemContentEntry::InvalidMetadata) { GemContentEntry.from_metadata("path" => "lib/foo.rb") }
      assert_raises(GemContentEntry::InvalidMetadata) { GemContentEntry.from_metadata("size" => "0") }
    end

    should "return a file entry" do
      entry = GemContentEntry.from_metadata(file_entry.metadata) { file_entry.body }

      assert_equal file_entry, entry
      assert_predicate entry, :file?
      assert_equal file_entry.body, entry.body
    end

    should "return an empty entry" do
      entry = GemContentEntry.from_metadata(empty_entry.metadata) { "" }

      assert_equal empty_entry, entry
      assert_predicate entry, :file?
      assert_equal "", entry.body
    end

    should "return a binary entry" do
      entry = GemContentEntry.from_metadata(binary_entry.metadata) { raise "binary not stored" }

      assert_equal binary_entry, entry
      assert_predicate entry, :file?
      refute_predicate entry, :text?
      assert_nil entry.body
    end

    should "return a symlink entry" do
      entry = GemContentEntry.from_metadata(symlink_entry.metadata)

      assert_equal symlink_entry, entry
      assert_predicate entry, :symlink?
    end

    should "return a large entry" do
      entry = GemContentEntry.from_metadata(large_entry.metadata) { raise "large not stored" }

      assert_equal large_entry, entry
      assert_predicate entry, :file?
      refute_predicate entry, :body_persisted?
    end
  end

  context "#body" do
    should "return nil for symlink" do
      assert_nil symlink_entry.body
    end

    should "return nil for large file" do
      assert_nil large_entry.body
    end

    should "return nil for binary file" do
      assert_nil binary_entry.body
    end

    should "return whatever string it is set to" do
      assert_equal "file body\nwith snowman emoji\n⛄️\n", file_entry.body
    end

    should "evaluates the reader on reading the body, yielding the entry itself" do
      evaluated = false
      entry = create_persisted_entry(file_entry.metadata) do |e|
        evaluated = true
        "body with SHA256: #{e.sha256}"
      end

      refute evaluated
      assert_equal "body with SHA256: #{entry.sha256}", entry.body
      assert evaluated
    end

    should "not evaluate the reader when setting the body with a block" do
      create_persisted_entry(file_entry.metadata) { raise }
    end
  end

  context "#sha256" do
    should "return the sha256 of the body" do
      assert_equal Digest::SHA256.hexdigest(file_entry.body), file_entry.sha256
    end

    should "return the sha256 of the body for a binary file" do
      assert_equal Digest::SHA256.hexdigest(binary_data), binary_entry.sha256
    end

    should "return sha256 of an empty file for an actual empty file" do
      assert_equal Digest::SHA256.hexdigest(""), empty_entry.sha256
    end

    should "return nil for a symlink" do
      assert_nil symlink_entry.sha256
    end

    should "return nil for a large entry" do
      assert_nil large_entry.sha256
    end

    should "return the sha256 for a persisted entry" do
      assert_equal Digest::SHA256.hexdigest(file_entry.body), persisted_file_entry.sha256
      assert_equal Digest::SHA256.hexdigest(binary_data), persisted_binary_entry.sha256
    end

    should "return nil for a persisted symlink entry" do
      assert_nil persisted_symlink_entry.sha256
    end

    should "return nil for a persisted large entry" do
      assert_nil persisted_large_entry.sha256
    end

    should "return value from initialization no matter what the body is" do
      entry = GemContentEntry.new(path: "badsha", sha256: "badsha", body: "foo", size: 3)

      assert_equal "badsha", entry.sha256
    end
  end

  context "#fingerprint" do
    should "return the content fingerprint" do
      assert_equal file_entry.sha256, file_entry.fingerprint
    end
  end

  context "#file_mode" do
    should "return the file mode octal string" do
      assert_equal "644", file_entry.file_mode
      assert_equal "755", binary_entry.file_mode
      assert_equal "20644", symlink_entry.file_mode
      assert_equal "644", persisted_file_entry.file_mode
      assert_equal "20644", persisted_symlink_entry.file_mode
    end
  end

  context "#mime" do
    should "return the mime type of the body" do
      assert_equal "text/plain; charset=utf-8", file_entry.mime
    end

    should "return the mime type of a binary file" do
      assert_equal "application/x-tar; charset=binary", binary_entry.mime
    end
  end

  context "#text?" do
    should "return true for text files" do
      assert_predicate file_entry, :text?
    end

    should "return true for json files" do
      json_entry ||= create_entry(
        path: "lib/foo.json",
        body: '{"foo": "bar"}'
      )

      assert_equal "application/json; charset=us-ascii", json_entry.mime
      assert_predicate json_entry, :text?
    end

    should "return false for binary files" do
      refute_predicate binary_entry, :text?
    end

    should "return false for symlinks" do
      refute_predicate symlink_entry, :text?
    end
  end

  context "#content_type" do
    should "return the mime type of the body" do
      assert_equal file_entry.mime, file_entry.content_type
    end
  end

  context "#size" do
    should "return the size of the body" do
      assert_equal file_entry.body.bytesize, file_entry.size
      assert_equal binary_data.bytesize, binary_entry.size
    end

    should "return 0 for symlink_entry" do
      assert_equal 0, symlink_entry.size
    end

    should "return the size of the body for a persisted entry" do
      assert_equal file_entry.size, persisted_file_entry.size
    end
  end

  context "#large?" do
    should "return true for large files" do
      assert_predicate large_entry, :large?
    end

    should "return false for small files" do
      refute_predicate file_entry, :large?
      refute_predicate empty_entry, :large?
      refute_predicate binary_entry, :large?
      refute_predicate symlink_entry, :large?
    end
  end

  context "#lines" do
    should "return the line count of the body" do
      assert_equal 3, file_entry.lines
    end

    should "return 0 for an empty file" do
      assert_equal 0, empty_entry.lines
    end

    should "return nil for large file, binary, or symlink" do
      assert_nil large_entry.lines
      assert_nil binary_entry.lines
      assert_nil symlink_entry.lines
    end
  end

  context "#symlink?" do
    should "return true if the entry is a symlink" do
      assert_predicate symlink_entry, :symlink?
    end

    should "return false if the entry is not a symlink" do
      refute_predicate file_entry, :symlink?
      refute_predicate empty_entry, :symlink?
      refute_predicate large_entry, :symlink?
      refute_predicate binary_entry, :symlink?
    end
  end

  context "#file?" do
    should "return true if the entry is a file" do
      assert_predicate file_entry, :file?
      assert_predicate large_entry, :file?
      assert_predicate empty_entry, :file?
      assert_predicate binary_entry, :file?
    end

    should "return false if the entry is not a file" do
      refute_predicate symlink_entry, :file?
    end
  end

  context "#persisted?" do
    should "return false if the entry is not persisted" do
      refute_predicate file_entry, :persisted?
      refute_predicate empty_entry, :persisted?
      refute_predicate large_entry, :persisted?
      refute_predicate binary_entry, :persisted?
      refute_predicate symlink_entry, :persisted?
    end

    should "return true if the entry is persisted" do
      assert_predicate persisted_file_entry, :persisted?
      assert_predicate persisted_empty_entry, :persisted?
      assert_predicate persisted_large_entry, :persisted?
      assert_predicate persisted_binary_entry, :persisted?
      assert_predicate persisted_symlink_entry, :persisted?
    end
  end

  context "#metadata" do
    should "return a Hash of the file entry's metadata" do
      expected = {
        "body_persisted" => "true",
        "file_mode" => file_entry.file_mode,
        "sha256" => file_entry.sha256,
        "lines" => file_entry.lines,
        "mime" => file_entry.mime,
        "path" => file_entry.path,
        "size" => file_entry.size
      }

      assert_equal expected, file_entry.metadata
    end

    should "return a Hash of the symlink entry's metadata" do
      expected = {
        "body_persisted" => "false",
        "file_mode" => symlink_entry.file_mode,
        "linkname" => symlink_entry.linkname,
        "path" => symlink_entry.path,
        "size" => symlink_entry.size
      }

      assert_equal expected, symlink_entry.metadata
    end
  end

  context "#body_persisted?" do
    should "return true if the entry is a file with text/* mime" do
      assert_predicate file_entry, :body_persisted?
      assert_predicate persisted_file_entry, :body_persisted?
    end

    should "return false if the entry is a binary file with application/* mime" do
      refute_predicate binary_entry, :body_persisted?
      refute_predicate persisted_binary_entry, :body_persisted?
    end

    should "return false if the entry is a symlink" do
      refute_predicate symlink_entry, :body_persisted?
      refute_predicate persisted_symlink_entry, :body_persisted?
    end

    should "return false if the entry is too large" do
      refute_predicate large_entry, :body_persisted?
      refute_predicate persisted_large_entry, :body_persisted?
    end
  end
end

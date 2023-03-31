# frozen_string_literal: true

class RubygemContents::Entry
  class InvalidMetadata < RuntimeError; end

  SIZE_LIMIT = 500.megabyte
  MIME_TEXTUAL_SUBTYPES = %w[json ld+json x-csh x-sh x-httpd-php xhtml+xml xml].freeze

  class << self
    def from_tar_entry(entry)
      attrs = {
        size: entry.size,
        path: entry.full_name,
        file_mode: entry.header.mode.to_fs(8)
      }

      if entry.size > SIZE_LIMIT
        head = entry.read(4096)
        mime = Magic.buffer(head, Magic::MIME)
        return new(mime: mime, **attrs)
      end

      # Using the linkname as the body, like git, makes it easier to show and diff symlinks. Thanks git!
      body = attrs[:linkname] = entry.header.linkname if entry.symlink?
      # read immediately because we're parsing a tar.gz and it shares a single IO across all entries.
      body ||= entry.read || ""

      new(
        body: body,
        mime: Magic.buffer(body, Magic::MIME),
        sha256: Digest::SHA256.hexdigest(body),
        **attrs
      )
    end

    def from_metadata(metadata, &)
      attrs = metadata.to_h.symbolize_keys.slice(:body_persisted, :file_mode, :lines, :linkname, :mime, :path, :sha256, :size)
      raise InvalidMetadata, "missing required keys: #{attrs.inspect}" if attrs[:path].blank? || attrs[:size].blank?
      attrs[:lines] = attrs[:lines]&.to_i
      attrs[:body_persisted] = attrs[:body_persisted] == "true"
      new(persisted: true, **attrs, &)
    end
  end

  attr_reader :path, :linkname, :file_mode, :lines, :sha256, :mime, :size
  alias fingerprint sha256
  alias content_type mime
  alias content_length size
  alias bytesize size

  def initialize(path:, size:, persisted: false, **attrs, &reader)
    @path = path
    @size = size.to_i
    @persisted = persisted

    @body_persisted, @file_mode, @lines, @linkname, @mime, @sha256 =
      attrs.values_at(:body_persisted, :file_mode, :lines, :linkname, :mime, :sha256)

    if @persisted
      @reader = reader if @body_persisted
    else
      @body_persisted = sha256.present? && !large? && text?
      @body = attrs[:body] if @body_persisted
      @lines = @body&.lines&.count unless symlink?
    end
  end

  def persisted?
    @persisted
  end

  def body_persisted?
    @body_persisted
  end

  def symlink?
    linkname.present?
  end

  def file?
    !symlink?
  end

  def large?
    size > SIZE_LIMIT
  end

  def empty?
    !symlink? && size.zero?
  end

  def text?
    return false unless mime
    return true if empty?
    return false if mime.end_with?("charset=binary")
    media_type, sub_type = mime.split(";").first.split("/")
    return true if media_type == "text"
    return false if media_type != "application"
    return true if MIME_TEXTUAL_SUBTYPES.include?(sub_type)
  end

  def body
    @body = @reader.call(self) if @reader
    @reader = nil
    @body
  end

  def metadata
    {
      "path" => path,
      "size" => size.to_s,
      "mime" => mime,
      "lines" => lines&.to_s,
      "sha256" => sha256,
      "linkname" => linkname,
      "file_mode" => file_mode,
      "body_persisted" => body_persisted? ? "true" : "false"
    }.compact
  end

  def base64_sha256
    sha256.presence && [[sha256].pack("H*")].pack("m0")
  end

  def ==(other)
    other.is_a?(self.class) && other.metadata == metadata
  end
end

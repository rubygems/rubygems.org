# frozen_string_literal: true

class RubygemContents::Entry
  class InvalidMetadata < RuntimeError; end

  # Reading 262 bytes is (supposedly) enough to determine the mime type of the entry.
  BYTES_FOR_MAGIC_DETECTION = 262
  SIZE_LIMIT = 100.megabytes
  MIME_TEXTUAL_SUBTYPES = %w[
    text/
    application/json
    application/ld\+json
    application/x-csh
    application/x-sh
    application/x-httpd-php
    application/xhtml\+xml
    application/xml
  ].freeze

  class << self
    # Passing in an existing Magic instance is very important for memory usage.
    # Magic.open(Magic::MIME) opens a new instance for each call and they are
    # very memory heavy.
    def from_tar_entry(entry, magic: Magic.open(Magic::MIME))
      attrs = {
        size: entry.size,
        path: entry.full_name,
        file_mode: entry.header.mode.to_fs(8)
      }

      if entry.size > SIZE_LIMIT
        mime = magic.buffer(entry.read(BYTES_FOR_MAGIC_DETECTION))
        return new(mime:, **attrs)
      end

      # Using the linkname as the body, like git, makes it easier to show and diff symlinks. Thanks git!
      body = attrs[:linkname] = entry.header.linkname if entry.symlink?
      # read immediately because we're parsing a tar.gz and it shares a single IO across all entries.
      body ||= entry.read || ""

      new(
        body: body,
        mime: magic.buffer(body),
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

  def initialize(path:, size:, persisted: false, **attrs, &reader) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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
      @lines = @body.count("\n") + (@body.end_with?("\n") || @body.empty? ? 0 : 1) if @body && !symlink?
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
    MIME_TEXTUAL_SUBTYPES.any? { |subtype| mime.start_with?(subtype) }
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

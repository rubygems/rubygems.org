class GemContentEntry
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

      if entry.symlink?
        new(linkname: entry.header.linkname, **attrs)
      elsif entry.size > SIZE_LIMIT
        head = entry.read(4096)
        mime = Magic.buffer(head, Magic::MIME)
        new(mime: mime, **attrs)
      else
        # read immediately because we're parsing a tar.gz and it shares a single IO across all entries.
        body = entry.read || ""
        new(
          body: body,
          mime: Magic.buffer(body, Magic::MIME),
          sha256: Digest::SHA256.hexdigest(body),
          **attrs
        )
      end
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
      @body = attrs[:body] if @body_persisted && text?
      @lines = @body&.lines&.count
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
    mime_type = MIME::Types[mime.split(";").first].first
    return false unless mime_type
    return true if mime_type.media_type == "text"
    return false if mime_type.media_type != "application"
    return true if MIME_TEXTUAL_SUBTYPES.include?(mime_type.sub_type)
  end

  def body
    @body = @reader.call(self) if @reader
    @reader = nil
    @body
  end

  def metadata
    {
      "path" => path,
      "size" => size,
      "mime" => mime,
      "lines" => lines,
      "sha256" => sha256,
      "linkname" => linkname,
      "file_mode" => file_mode,
      "body_persisted" => body_persisted? ? "true" : "false"
    }.compact
  end

  def ==(other)
    other.is_a?(self.class) && other.metadata == metadata
  end
end

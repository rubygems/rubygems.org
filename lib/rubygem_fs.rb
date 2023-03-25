# frozen_string_literal: true

require "aws-sdk-s3"


module RubygemFs
  class Instrumenter
    def initialize(rubygem_fs)
      @rubygem_fs = rubygem_fs
      @local = @rubygem_fs.is_a?(RubygemFs::Local)
    end

    # Don't instrument boring methods
    delegate :in_bucket, :bucket, :base_dir, to: :@rubygem_fs

    def get(key)
      instrument(:get, key:) { @rubygem_fs.get(key) }
    end

    def head(key)
      instrument(:head, key:) { @rubygem_fs.head(key) }
    end

    def store(key, body, **options)
      instrument(:store, key:, options:) { @rubygem_fs.store(key, body, **options) }
    end

    def ls(root, path = nil)
      instrument(:ls, root:, path:) { @rubygem_fs.ls(root, path) }
    end

    def each_key(**options, &)
      instrument(:each_key, **options) { @rubygem_fs.each_key(**options) }
    end

    def remove(*keys, &)
      instrument(:remove, keys:) { @rubygem_fs.remove(*keys) }
    end

    private

    def instrument(method, **payload, &)
      ActiveSupport::Notifications.instrument("rubygem_fs.#{method}", bucket: bucket, local: @local, **payload, &)
    end
  end

  def self.instance
    @fs ||=
      if Rails.env.development?
        RubygemFs::Instrumenter.new(RubygemFs::Local.new)
      else
        RubygemFs::S3.new
      end
  end

  def self.contents
    @contents ||= Instrumenter.new instance.in_bucket(Gemcutter.config.s3_contents_bucket)
  end

  def self.mock!
    @contents = nil
    @fs = RubygemFs::Local.new(Dir.mktmpdir)
  end

  def self.s3!(host)
    @contents = nil
    @fs = RubygemFs::S3.new(access_key_id: "k",
                            secret_access_key: "s",
                            endpoint: host,
                            force_path_style: true)
    @fs.define_singleton_method(:init) do
      s3.create_bucket(bucket: bucket)
    end
    @fs.init
  end

  class Local
    class InvalidPathError < ArgumentError; end

    METADATA_DIR = "_metadata"

    attr_reader :base_dir

    def initialize(base_dir = nil)
      base_dir ||= Rails.root.join("server")
      @base_dir = Pathname.new(base_dir).expand_path
      @base_dir.mkpath
      @metadata = in_bucket(METADATA_DIR) unless @base_dir.to_s.end_with?(METADATA_DIR)
    end

    def bucket
      base_dir.basename.to_s
    end

    def in_bucket(dir)
      self.class.new(path_for(dir))
    end

    def store(key, body, **kwargs)
      path = path_for key
      @metadata&.store(key, JSON.generate(kwargs.merge(key: key))) if kwargs.present?
      path.dirname.mkpath
      path.binwrite body
    end

    def head(key)
      return unless @metadata && path_for(key).file?
      JSON.parse(@metadata.get(key).to_s).symbolize_keys
    rescue Errno::ENOENT, JSON::ParserError
      { key: key, metadata: {} }
    end

    def get(key)
      body = path_for(key).binread
      fix_encoding(body, key)
    rescue Errno::ENOENT, Errno::EISDIR
      nil
    end

    def each_key(prefix: nil, &)
      return enum_for(__method__, prefix:) unless block_given?
      base = dir_for(prefix)
      return unless base.directory?
      base.find do |entry|
        next if entry.directory?
        path = key_for(entry)
        next if path.start_with?(METADATA_DIR)
        yield path
      end
      nil
    end

    # root and path are passed separately to ensure that the path stays within the root
    # without this we could only contain it within the entire rubygemfs file system
    def ls(root, path = nil)
      root_dir = dir_for(root)
      base = dir_for(path, root_dir)
      return [[], []] unless base.directory?
      dirs, files = base.children.sort.partition(&:directory?)
      dirs.delete(@metadata&.base_dir)
      [
        dirs.map { |dir| "#{key_for(dir)}/" },
        files.map { |file| key_for(file) }
      ]
    end

    def remove(*keys)
      @metadata&.remove(*keys)
      keys.flatten.reject do |key|
        path_for(key).ascend.take_while { |entry| descendant?(entry) && entry.delete }
        true
      rescue Errno::ENOTEMPTY
        true
      rescue Errno::ENOENT
        false
      end
    end

    private

    def path_for(key, base = @base_dir)
      key = key.to_s.sub(%r{^/+}, "")
      path = base.join(key).expand_path
      raise InvalidPathError, "key #{key.inspect} is outside of base #{base.inspect}" unless descendant?(path, base)
      path
    end

    def dir_for(prefix, base = @base_dir)
      return base if prefix.blank?
      raise InvalidPathError, "prefix #{prefix.inspect} must end in / to avoid ambiguous behavior" unless prefix.to_s.end_with?("/")
      path_for(prefix, base)
    end

    def fix_encoding(body, key)
      charset = charset_for(key) || Magic.buffer(body, Magic::MIME_ENCODING)
      body.force_encoding(charset) if charset
      body
    end

    def charset_for(key)
      content_type = head(key)&.fetch(:content_type, nil)
      Regexp.last_match(1) if content_type =~ /charset=(.+)$/
    end

    # always return key relative to bucket, same as S3
    def key_for(path)
      path.relative_path_from(@base_dir).to_s
    end

    def descendant?(path, base = @base_dir)
      path.to_s.start_with?(base.to_s) && path != base
    end
  end

  class S3
    attr_reader :bucket

    def initialize(config = {})
      @bucket = config.delete(:bucket) || Gemcutter.config["s3_bucket"]
      @config = {
        access_key_id: ENV["S3_KEY"],
        secret_access_key: ENV["S3_SECRET"],
        region: Gemcutter.config["s3_region"],
        endpoint: "https://#{Gemcutter.config['s3_endpoint']}"
      }.merge(config)
    end

    def in_bucket(bucket)
      self.class.new(@config.merge(bucket: bucket))
    end

    def store(key, body, metadata: {}, **kwargs)
      allowed_args = kwargs.slice(:content_type, :checksum_sha256, :content_encoding)
      s3.put_object(key: key,
                    body: body,
                    bucket: bucket,
                    acl: "public-read",
                    metadata: metadata,
                    cache_control: "max-age=31536000",
                    **allowed_args)
    end

    def head(key)
      s3.head_object(key: key, bucket: bucket).to_h
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end

    def get(key)
      s3.get_object(key: key, bucket: bucket).body.read
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end

    # To list only the root level objects in the bucket, you send a GET request
    # on the bucket with the slash (/) delimiter character. In response, Amazon
    # S3 returns keys that do not contain the / delimiter character. All other
    # keys contain the delimiter character are grouped and returned in a single
    # common_prefixes element with the prefix value `dir/`, which is a substring
    # from the beginning of these keys to the first occurrence of the delimiter.
    #
    # resp.common_prefixes #=> Array
    # resp.common_prefixes[0].prefix #=> String
    def each_key(prefix: nil, delimiter: nil, &)
      return enum_for(__method__, prefix:, delimiter:) unless block_given?
      s3.list_objects_v2(bucket: bucket, prefix:, delimiter:).each do |response|
        response.common_prefixes.each { |object| yield object.prefix } if delimiter
        response.contents.each { |object| yield object.key }
      end
    end

    def remove(*keys)
      errors = []
      # API is limited to 1000 keys per request.
      keys.flatten.each_slice(1000) do |group|
        resp = s3.delete_objects(
          bucket: bucket,
          delete: {
            objects: group.map { |key| { key: key } },
            quiet: true # only return errors
          }
        )
        errors << resp.errors.map(&:key)
      end
      errors.flatten
    end

    def restore(key)
      s3.head_object(key: key, bucket: bucket)
    rescue Aws::S3::Errors::NotFound => e
      version_id = e.context.http_response.headers["x-amz-version-id"]
      s3.delete_object(key: key, bucket: bucket, version_id: version_id)
    end

    private

    def s3
      @s3 ||= Aws::S3::Client.new(@config)
    end
  end
end

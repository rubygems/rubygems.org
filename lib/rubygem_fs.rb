require "aws-sdk-s3"

module RubygemFs
  def self.instance
    @fs ||=
      if Rails.env.development?
        RubygemFs::Local.new
      else
        RubygemFs::S3.new
      end
  end

  def self.contents
    @content ||= instance.in_bucket Gemcutter.config.s3_contents_bucket
  end

  def self.mock!
    @content = nil
    @fs = RubygemFs::Local.new(Dir.mktmpdir)
  end

  def self.s3!(host)
    @content = nil
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
    class UnsafePathError < RuntimeError; end

    attr_reader :base_dir

    def initialize(base_dir = nil)
      base_dir ||= Rails.root.join("server")
      @base_dir = Pathname.new(base_dir).expand_path
      @base_dir.mkpath
      @metadata = in_bucket("_metadata") unless @base_dir.to_s.end_with?("_metadata")
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
      JSON.parse(@metadata&.get(key).to_s).symbolize_keys if path_for(key).exist?
    rescue Errno::ENOENT, JSON::ParserError
      { key: key, metadata: {} }
    end

    def get(key)
      path_for(key).binread
    rescue Errno::ENOENT
      nil
    end

    def each_key(prefix: "", &)
      return enum_for(__method__, prefix: prefix) unless block_given?
      # it's easier to list everything and filter on strings because file systems don't act like S3
      @base_dir.find do |entry|
        path = entry.relative_path_from(@base_dir).to_s
        next unless path.start_with?(prefix)
        next if entry.directory?
        yield path
      end
    end

    def remove(*keys)
      @metadata&.remove(*keys)
      keys.flatten.reject do |key|
        path_for(key).ascend { |entry| descendant?(entry) ? entry.delete : break }
        true
      rescue Errno::ENOTEMPTY
        true
      rescue Errno::ENOENT
        false
      end
    end

    private

    def path_for(key, base = @base_dir)
      key = key.sub(%r{^/+}, "")
      path = base.join(key).expand_path
      raise UnsafePathError, "Unsafe path: #{key} is outside of base: #{@base_dir}" unless descendant?(path)
      path
    end

    def descendant?(path)
      path.to_s.start_with?(@base_dir.to_s) && path != @base_dir
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

    def each_key(prefix: nil, &)
      return enum_for(__method__, prefix: prefix) unless block_given?
      s3.list_objects_v2(bucket: bucket, prefix: prefix).each do |response|
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

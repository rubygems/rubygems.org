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

  def self.mock!
    @fs = RubygemFs::Local.new(Dir.mktmpdir)
  end

  def self.s3!(host)
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
    attr_reader :base_dir

    def initialize(base_dir = nil)
      base_dir ||= Rails.root.join("server")
      @base_dir = Pathname.new(base_dir).expand_path
    end

    def store(key, body, **)
      path = path_for(key)
      path.dirname.mkpath
      path.binwrite(body)
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
      keys.flatten.reject { |key| delete(key) }
    end

    private

    def delete(key)
      path = path_for(key)
      return false unless descendant?(path)
      path.ascend do |entry|
        break unless descendant?(entry)
        entry.delete
      end
      true
    rescue Errno::ENOTEMPTY
      true
    rescue Errno::ENOENT
      false
    end

    def path_for(key)
      key = key.sub(%r{^/+}, "")
      @base_dir.join(key).expand_path
    end

    def descendant?(path)
      path.to_s.start_with?(@base_dir.to_s) && path != @base_dir
    end
  end

  class S3
    def initialize(config = {})
      @bucket = config.delete(:bucket)
      @config = {
        access_key_id: ENV["S3_KEY"],
        secret_access_key: ENV["S3_SECRET"],
        region: Gemcutter.config["s3_region"],
        endpoint: "https://#{Gemcutter.config['s3_endpoint']}"
      }.merge(config)
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

    def bucket
      @bucket || Gemcutter.config["s3_bucket"]
    end

    private

    def s3
      @s3 ||= Aws::S3::Client.new(@config)
    end
  end
end

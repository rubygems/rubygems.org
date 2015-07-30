module RubygemFs
  def self.instance
    @fs ||=
      if Rails.env.development?
        RubygemFs::Local.new
      else
        RubygemFs::S3.new(access_key_id: ENV['S3_KEY'],
                          secret_access_key: ENV['S3_SECRET'],
                          region: 'us-east-1',
                          endpoint: "https://s3.amazonaws.com")
      end
  end

  def self.mock!
    @fs = RubygemFs::Local.new
    def @fs.base_dir
      @dir ||= Dir.mktmpdir
    end
  end

  def self.s3!(host)
    @fs = RubygemFs::S3.new(access_key_id: 'k',
                            secret_access_key: 's',
                            region: 'us-east-1',
                            endpoint: host,
                            force_path_style: true)
    def @fs.init
      s3.create_bucket(bucket: bucket)
    end
    @fs.init
  end

  class Local
    def store(key, body, _metadata = {})
      FileUtils.mkdir_p File.dirname("#{base_dir}/#{key}")
      File.open("#{base_dir}/#{key}", 'wb') do |f|
        f.write(body)
      end
    end

    def get(key)
      File.read("#{base_dir}/#{key}")
    rescue Errno::ENOENT
      nil
    end

    def remove(key)
      FileUtils.rm("#{base_dir}/#{key}")
    rescue Errno::ENOENT
      false
    end

    def base_dir
      Rails.root.join('server')
    end
  end

  class S3
    def initialize(config)
      @config = config
    end

    def store(key, body, metadata = {})
      s3.put_object(key: key, body: body, bucket: bucket, acl: 'public-read', metadata: metadata)
    end

    def get(key)
      s3.get_object(key: key, bucket: bucket).body.read
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end

    def remove(key)
      s3.delete_object(key: key, bucket: bucket)
    end

    def restore(key)
      s3.head_object(key: key, bucket: bucket)
    rescue Aws::S3::Errors::NoSuchKey => e
      version_id = e.context.http_response.headers["x-amz-version-id"]
      s3.delete_object(key: key, bucket: bucket, version_id: version_id)
    end

    private

    def bucket
      Gemcutter.config['s3_bucket']
    end

    def s3
      @s3 ||= Aws::S3::Client.new(@config)
    end
  end
end

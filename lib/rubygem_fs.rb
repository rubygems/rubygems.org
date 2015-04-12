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
    @fs = RubygemFs::Local.new.tap do |fs|
      def fs.base_dir
        @dir ||= Dir.mktmpdir
      end
    end
  end

  def self.s3!(host)
    @fs = RubygemFs::S3.new
    s3 = @fs.s3(access_key_id: 'k', secret_access_key: 's', endpoint: host, force_path_style: true, region: 'us-west-1')
    s3.create_bucket(bucket: Gemcutter.config['s3_bucket'])
  end

  class Local
    def store(key, body)
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
    def store(key, body)
      s3.put_object(key: key, body: body, bucket: bucket, acl: 'public-read')
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
      begin
        s3.get_object(key: key, bucket: bucket);
      rescue Aws::S3::Errors::NoSuchKey=> e
        version_id = e.context.http_response.headers["x-amz-version-id"]
        s3.delete_object(key: key, bucket: bucket, version_id: version_id)
      end
    end

    def bucket
      Gemcutter.config['s3_bucket']
    end

    def s3(options = nil)
      @s3 ||= Aws::S3::Client.new(options ||
                                  { access_key_id: ENV['S3_KEY'],
                                    secret_access_key: ENV['S3_SECRET'],
                                    endpoint: "https://s3.amazonaws.com" })
    end
  end
end

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
    uri = URI(host)
    @fs = RubygemFs::S3.new
    s3 = @fs.s3(access_key_id: 'k', secret_access_key: 's',  proxy: {host: uri.host, port: uri.port})
    s3.buckets.build(Gemcutter.config['s3_bucket']).save
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
    rescue
      nil
    end

    def remove(key)
      FileUtils.rm("#{base_dir}/#{key}")
    end

    private
    def base_dir
      Rails.root.join('server')
    end
  end

  class S3
    def store(key, body)
      object = bucket.objects.build(key)
      object.content = body
      object.save
    end

    def get(key)
      if object = bucket.objects.find(key)
        object.content
      end
    end

    def remove(key)
      if object = bucket.objects.find(key)
        object.destroy
      end
    end

    def bucket
      @bucket ||= s3.buckets.find(Gemcutter.config['s3_bucket'])
    end

    def s3(options = nil)
      @s3 ||= ::S3::Service.new(options || { access_key_id: ENV['S3_KEY'], secret_access_key: ENV['S3_SECRET'] })
    end
  end
end

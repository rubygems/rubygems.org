class GemTarBuilder
  def initialize
    @entries = []
    @digests = {}
  end

  def metadata(content)
    yaml = content.is_a?(String) ? content : content.to_yaml
    @entries << [:metadata_gz, yaml]
  end

  def data(&block)
    @entries << [:data_tar_gz, block]
  end

  def checksums(mode = nil, raw: nil, &block)
    @entries << [:checksums_yaml_gz,  mode:, raw:, block:]
  end

  def file(name, content)
    @entries << [:raw_file, name:, content:]
  end

  def to_io
    tar = StringIO.new("".b)

    Gem::Package::TarWriter.new(tar) do |gem_tar|
      @entries.each do |type, value|
        case type
        when :metadata_gz
          write_metadata_gz(gem_tar, value)
        when :data_tar_gz
          write_data_tar_gz(gem_tar, value)
        when :checksums_yaml_gz
          write_checksums_yaml_gz(gem_tar, value)
        when :raw_file
          write_raw_file(gem_tar, value[:name], value[:content])
        end
      end
    end

    tar.rewind
    tar
  end

  private

  def write_metadata_gz(gem_tar, yaml)
    sha256 = OpenSSL::Digest.new("SHA256")
    sha512 = OpenSSL::Digest.new("SHA512")

    gem_tar.add_file "metadata.gz", 0o444 do |io|
      Gem::Package::DigestIO.wrap(io, [["SHA256", sha256], ["SHA512", sha512]]) do |dio|
        gz_io = Zlib::GzipWriter.new dio, Zlib::BEST_COMPRESSION
        gz_io.write yaml
        gz_io.close
      end
      @digests["metadata.gz"] = { "SHA256" => sha256.hexdigest, "SHA512" => sha512.hexdigest }
    end
  end

  def write_data_tar_gz(gem_tar, block)
    sha256 = OpenSSL::Digest.new("SHA256")
    sha512 = OpenSSL::Digest.new("SHA512")

    gem_tar.add_file "data.tar.gz", 0o444 do |io|
      Gem::Package::DigestIO.wrap(io, [["SHA256", sha256], ["SHA512", sha512]]) do |dio|
        gz_io = Zlib::GzipWriter.new dio, Zlib::BEST_COMPRESSION
        if block
          Gem::Package::TarWriter.new(gz_io, &block)
        else
          Gem::Package::TarWriter.new gz_io do |data_tar|
            data = "hello world"
            data_tar.add_file_simple "testing.txt", 0o444, data.bytesize do |file_io|
              file_io.write data
            end
          end
        end
        gz_io.close
      end
      @digests["data.tar.gz"] = { "SHA256" => sha256.hexdigest, "SHA512" => sha512.hexdigest }
    end
  end

  def write_checksums_yaml_gz(gem_tar, opts)
    mode = opts[:mode]
    raw = opts[:raw]
    block = opts[:block]

    gem_tar.add_file "checksums.yaml.gz", 0o444 do |io|
      gz_io = Zlib::GzipWriter.new io, Zlib::BEST_COMPRESSION
      if raw
        gz_io.write raw
      elsif mode == :auto || block
        dsl = ChecksumsDSL.new(@digests)
        dsl.auto if mode == :auto
        dsl.instance_eval(&block) if block
        gz_io.write Psych.dump(dsl.to_h)
      else
        gz_io.write Psych.dump({})
      end
      gz_io.close
    end
  end

  def write_raw_file(gem_tar, name, content)
    sha256 = OpenSSL::Digest.new("SHA256")
    sha512 = OpenSSL::Digest.new("SHA512")

    gem_tar.add_file name, 0o444 do |io|
      sha256 << content
      sha512 << content
      io.write content
    end

    @digests[name] = { "SHA256" => sha256.hexdigest, "SHA512" => sha512.hexdigest }
  end

  class ChecksumsDSL
    def initialize(digests)
      @digests = digests
      @checksums = {}
    end

    def auto
      %w[SHA256 SHA512].each do |algo|
        @checksums[algo] ||= {}
        @digests.each do |entry_name, algos|
          @checksums[algo][entry_name] = algos[algo] if algos[algo]
        end
      end
    end

    def to_h
      @checksums
    end

    def method_missing(algo_name, entries = nil)
      key = algo_name.to_s.upcase
      if entries
        @checksums[key] ||= {}
        @checksums[key].merge!(entries)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.match?(/\A[a-z0-9_]+\z/) || super
    end
  end
end

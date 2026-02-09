module GemHelpers # rubocop:disable Metrics/ModuleLength
  def gem_tar_builder(&block)
    builder = GemTarBuilder.new
    builder.instance_eval(&block)
    builder.to_io
  end

  def gem_specification_from_gem_fixture(name)
    Gem::Package.new(File.join("test", "gems", "#{name}.gem")).spec
  end

  def gem_file(name = "test-0.0.0.gem", &)
    Rails.root.join("test", "gems", name.to_s).open("rb", &)
  end

  def build_gemspec(gemspec)
    Gem::DefaultUserInteraction.use_ui(Gem::StreamUI.new(StringIO.new, StringIO.new)) do
      Gem::Package.build(gemspec, true)
    end
  end

  def build_gem(spec, key: nil) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    checksums = {
      "SHA256" => {},
      "SHA512" => {}
    }
    tar = StringIO.new("".b)

    Gem::Package::TarWriter.new(tar) do |gem_tar|
      sha256 = OpenSSL::Digest.new "SHA256"
      sha512 = OpenSSL::Digest.new "SHA512"

      gem_tar.add_file "metadata.gz", 0o444 do |io|
        yaml = spec.is_a?(String) ? spec : spec.to_yaml
        Gem::Package::DigestIO.wrap(io, [["SHA256", sha256], ["SHA512", sha512]]) do |dio|
          gz_io = Zlib::GzipWriter.new dio, Zlib::BEST_COMPRESSION
          gz_io.write yaml
          gz_io.close
        end
        checksums["SHA256"]["metadata.gz"] = sha256.hexdigest
        checksums["SHA512"]["metadata.gz"] = sha512.hexdigest
      end

      if key.present?
        gem_tar.add_file "metadata.gz.sig", 0o444 do |io|
          io.write key.sign(OpenSSL::Digest.new("SHA256").new, sha256.digest)
        end
      end

      sha256 = OpenSSL::Digest.new "SHA256"
      sha512 = OpenSSL::Digest.new "SHA512"

      gem_tar.add_file "data.tar.gz", 0o444 do |io|
        Gem::Package::DigestIO.wrap(io, [["SHA256", sha256], ["SHA512", sha512]]) do |dio|
          gz_io = Zlib::GzipWriter.new dio, Zlib::BEST_COMPRESSION
          Gem::Package::TarWriter.new gz_io do |data_tar|
            data = "hello world"
            data_tar.add_file_simple "lib/testing.txt", 0o444, data.bytesize do |file_io|
              file_io.write data
            end
          end
          gz_io.close
        end
        checksums["SHA256"]["data.tar.gz"] = sha256.hexdigest
        checksums["SHA512"]["data.tar.gz"] = sha512.hexdigest
      end

      if key.present?
        gem_tar.add_file "data.tar.gz.sig", 0o444 do |io|
          io.write key.sign(OpenSSL::Digest.new("SHA256").new, sha256.digest)
        end
      end

      sha256 = OpenSSL::Digest.new "SHA256"
      sha512 = OpenSSL::Digest.new "SHA512"

      gem_tar.add_file "checksums.yaml.gz", 0o444 do |io|
        Gem::Package::DigestIO.wrap(io, [["SHA256", sha256], ["SHA512", sha512]]) do |dio|
          gz_io = Zlib::GzipWriter.new dio, Zlib::BEST_COMPRESSION
          gz_io.write Psych.dump(checksums)
          gz_io.close
        end
        checksums["SHA256"]["checksums.yaml.gz"] = sha256.hexdigest
        checksums["SHA512"]["checksums.yaml.gz"] = sha512.hexdigest
      end

      if key.present?
        gem_tar.add_file "checksums.yaml.gz.sig", 0o444 do |io|
          io.write key.sign(OpenSSL::Digest.new("SHA256").new, sha256.digest)
        end
      end

      yield gem_tar if block_given?
    end

    StringIO.new(tar.string)
  end

  def build_gem_raw(file_name:, spec:, contents_writer: nil)
    package = Gem::Package.new file_name

    File.open(file_name, "wb") do |file|
      Gem::Package::TarWriter.new(file) do |gem|
        gem.add_file "metadata.gz", 0o444 do |io|
          package.gzip_to(io) do |gz_io|
            gz_io.write spec
          end
        end
        gem.add_file "data.tar.gz", 0o444 do |io|
          package.gzip_to io do |gz_io|
            Gem::Package::TarWriter.new gz_io do |data_tar|
              contents_writer[data_tar] if contents_writer
            end
          end
        end
      end
    end
  end

  def new_gemspec(name, version, summary, platform, extra_args = {})
    ruby_version = extra_args[:ruby_version]
    rubygems_version = extra_args[:rubygems_version]
    Gem::Specification.new do |s|
      s.name = name
      s.platform = platform
      s.version = version.to_s
      s.authors = ["Someone"]
      s.date = Time.zone.now.strftime("%Y-%m-%d")
      s.description = summary.to_s
      s.email = "someone@example.com"
      s.files = []
      s.homepage = "http://example.com/#{name}"
      s.require_paths = ["lib"]
      s.summary = summary.to_s
      s.test_files = []
      s.licenses = []
      s.required_ruby_version = ruby_version
      s.required_rubygems_version = rubygems_version
      s.metadata = { "foo" => "bar" }
      yield s if block_given?
    end
  end
end

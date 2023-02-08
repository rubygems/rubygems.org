module GemInclusions
  class Package
    def initialize(package)
      @package = package
    end

    delegate :contents, :spec, to: :@package

    def each(&)
      @package.gem.with_read_io do |io|
        gem_tar = ::Gem::Package::TarReader.new io
        gem_tar.seek("data.tar.gz") do |entry|
          @package.open_tar_gz(entry) do |data_tar|
            data_tar.each(&)
          end
        end
      end
    end

    def validate
      each_content do |entry|
        validate_path(entry.full_name)
        validate_symlink(entry.full_name, entry.header.linkname) if entry.symlink?
      end
    end

    def validate_path(path)
      raise Gem::Package::PathError.new(path, "install_directory") unless safe_path?(path)
    end

    def validate_symlink(path, linkname)
      target = Pathname.new(path).dirname.join(linkname)
      raise Gem::Package::SymlinkError.new(path, target.to_s, "install_directory") unless safe_path?(target)
    end

    def safe_path?(path)
      return false if Pathname.new(path).absolute?
      root = Pathname.new("/#{SecureRandom.hex}/")
      return false unless root.join(path).cleanpath.to_s.start_with?(root.to_s)
      true
    end
  end
end

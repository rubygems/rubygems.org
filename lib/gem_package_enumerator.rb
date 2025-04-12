# frozen_string_literal: true

##
# A wrapper around Gem::Package to provide an enumerator for files in the gem.

class GemPackageEnumerator
  def initialize(package)
    @package = package
    return if @package.respond_to?(:each_file) || @package.respond_to?(:verify)
    raise ArgumentError, "package must be a Gem::Package"
  end

  # NOTE: For efficiency sake we do not verify the gem before reading the
  # contents. This means that if you try to access anything on the package
  # before IO.rewind is called, it will crash trying to read from the wrong
  # position. This saves as much memory allocation as the unpacked size of
  # the gem.
  def each(&blk)
    return enum_for(__method__).lazy unless blk
    open_data_tar { |data_tar| data_tar.each(&blk) }
  end

  def map(&)
    each.lazy.map(&)
  end

  def filter_map(&)
    each.lazy.filter_map(&)
  end

  private

  def open_data_tar(&)
    @package.gem.with_read_io do |io|
      Gem::Package::TarReader.new(io).seek("data.tar.gz") do |gem_entry|
        @package.open_tar_gz(gem_entry, &)
      end
    end
  end
end

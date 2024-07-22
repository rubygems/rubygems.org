# frozen_string_literal: true

##
# A wrapper around Gem::Package to provide an enumerator for files in the gem.

class GemPackageEnumerator
  def initialize(package)
    @package = package
    return if @package.respond_to?(:each_file) || @package.respond_to?(:verify)
    raise ArgumentError, "package must be a Gem::Package"
  end

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

  def open_data_tar(&blk)
    @package.verify
    @package.gem.with_read_io do |io|
      Gem::Package::TarReader.new(io).seek("data.tar.gz") do |gem_entry|
        @package.open_tar_gz(gem_entry, &blk)
      end
    end
  end
end

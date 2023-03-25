class ContentPresenter
  attr_reader :rubygem, :version, :path, :gem_version, :pathname, :entry

  def initialize(rubygem, version, path)
    @rubygem = rubygem
    @version = version
    @gem_version = version.to_gem_version
    @path = path || ""
    if @path.present?
      @entry = @version.manifest.entry(@path)
      @path = path.to_s.sub(%r{/?$}, "/") unless @entry
    end
    @pathname = Pathname.new(@path)
  end

  def breadcrumbs
    return if dirname.to_s.blank?
    dirname.descend do |part|
      yield part.basename.to_s, part.to_s
    end
  end

  def dirname
    @dirname ||= @entry ? @pathname.parent : @pathname
    @dirname = Pathname.new("") if @dirname.to_s == "."
    @dirname
  end

  def root?
    @path.blank?
  end

  def parent?
    !root?
  end

  def parent_path
    @pathname.parent.to_s
  end

  def basename
    @pathname.basename.to_s
  end

  def present?
    entry.present? || dirs.present? || files.present?
  end

  def blank?
    !present?
  end

  def dirs
    return @dirs if defined?(@dirs)
    @dirs, @files = @version.manifest.ls(@path)
    @dirs
  end

  def files
    return @files if defined?(@files)
    @dirs, @files = @version.manifest.ls(@path)
    @files
  end

  def each_dir
    dirs.each do |dir|
      dirpath = @pathname.join(dir)
      dir_last_modified_version = rollup_last_modified_version_in_dir(dirpath)
      yield dir.to_s, dirpath.to_s, dir_last_modified_version
    end
  end

  def each_file
    files.each do |file|
      filepath = @pathname.join(file)
      entry = @version.manifest.entry(filepath)
      yield file.to_s, filepath.to_s, last_modified_version(entry), entry
    end
  end

  def last_modified_version(entry)
    return nil unless entry.sha256
    version_checksums.take_while { |_version, checksums| checksums[entry.path] == entry.sha256 }.last.first
  end

  def previous_versions
    @previous_versions ||= @rubygem
      .public_versions
      .where(platform: @version.platform)
      .reject { |v| v.to_gem_version > @gem_version }
  end

  def checksums(version)
    @checksums_for ||= {}
    @checksums_for[version.id] ||= version.manifest.checksums
  end

  def version_checksums
    @version_checksums ||=
      # Array.new(previous_versions.size) { |i| [previous_versions[i], checksums(previous_versions[i])] }
      Enumerator.new(previous_versions.size) do |yielder|
        previous_versions.each do |version|
          yielder << [version, checksums(version)]
        end
      end
  end

  def rollup_last_modified_version_in_dir(dirpath)
    current = checksums_in_dir(dirpath, checksums(@version))
    version_checksums.take_while { |_, checksums| current == checksums_in_dir(dirpath, checksums) }.last.first
  end

  # given a dirpath, return the list of file -> checksums included under that dir
  def checksums_in_dir(dirpath, checksums)
    dirpath = dirpath.to_s
    checksums.select { |path, _| path.start_with?(dirpath) }.sort
  end
end

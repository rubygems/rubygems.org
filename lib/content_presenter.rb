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
    return if @path.blank?
    (@entry ? @pathname.parent : @pathname).descend do |part|
      yield part.basename.to_s, part.to_s
    end
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
      yield dir.to_s, dirpath.to_s
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
    version_checksums.take_while { |_version, checksums| checksums[entry.path] == entry.sha256 }.last&.first
  end

  def version_checksums
    @version_checksums ||= @rubygem
      .public_versions
      .where(platform: @version.platform)
      .reject { |v| v.to_gem_version > @gem_version }
      .index_with { |v| v.manifest.checksums }
      .compact_blank
  end
end

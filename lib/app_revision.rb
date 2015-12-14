class AppRevision
  def self.version
    @version ||= begin
      revision_file.read
    rescue Errno::ENOENT
      `git rev-parse HEAD`
    end.strip
  end

  def self.revision_file
    Rails.root.join('REVISION')
  end
end

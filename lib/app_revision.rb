class AppRevision
  def self.version
    @version ||= revision_or_fallback
  end

  def self.revision_or_fallback
    begin
      revision_file.read
    rescue Errno::ENOENT
      `git rev-parse HEAD`
    end.strip
  end

  def self.revision_file
    Rails.root.join('REVISION')
  end
end

class AppRevision
  def self.version
    @version ||= revision_or_fallback
  end

  def self.revision_or_fallback
    begin
      revision_file.read
    rescue Errno::ENOENT
      begin
        git_revision
      rescue Errno::ENOENT
        "UNKNOWN"
      end
    end.strip
  end

  def self.revision_file
    Rails.root.join("REVISION")
  end

  def self.git_revision
    `git rev-parse HEAD`
  end
end

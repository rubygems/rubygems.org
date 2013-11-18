# Wraps a simple interface around the fog library, so we don't need to directly
# depend on it everywhere.
class PublicFileBucket
  def initialize(fog_directory)
    @directory = fog_directory
  end

  def create(path, content)
    directory.files.create(
      key:    path,
      body:   content,
      public: true
    )
  end

  def get(path, opts = {})
    directory.files.get(path).body
  end

  private

  attr_reader :directory
end

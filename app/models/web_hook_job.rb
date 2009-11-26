class WebHookJob
  attr_reader :hook, :gem

  def initialize(hook, gem)
    @hook = hook
    version = gem.versions.latest
    @gem  = {
      'name'                    => gem.name,
      'version'                 => version.number,
      'rubyforge_project'       => version.rubyforge_project,
      'description'             => version.description,
      'summary'                 => version.summary,
      'authors'                 => version.authors,
      'downloads'               => gem.downloads
    }
  end
end

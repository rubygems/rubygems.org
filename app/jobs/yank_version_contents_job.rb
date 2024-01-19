class YankVersionContentsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with total_limit: 1, key: -> { "yank-contents-#{version_arg&.full_name}" }
  queue_as :version_contents

  class VersionNotYanked < RuntimeError; end

  discard_on ActiveJob::DeserializationError

  retry_on VersionNotYanked, wait: :polynomially_longer, attempts: 5

  def version_arg
    arguments.first[:version]
  end

  def perform(version:)
    raise VersionNotYanked, "Version #{version&.full_name.inspect} is not yanked" unless version&.yanked?
    logger.info "Yanking gem contents for #{version.full_name}"
    version.manifest.yank
    logger.info "Yanking gem contents for #{version.full_name} succeeded"
  end
end

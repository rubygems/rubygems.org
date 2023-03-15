class StoreVersionContentsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with total_limit: 1, key: -> { "store-contents-#{version_arg.full_name}" }
  queue_as :version_contents

  class VersionNotIndexed < RuntimeError; end
  class GemNotFound < RuntimeError; end

  discard_on ActiveJob::DeserializationError
  discard_on Gem::Package::FormatError, Gem::Security::Exception

  retry_on VersionNotIndexed, wait: :exponentially_longer, attempts: 5
  retry_on GemNotFound, wait: :exponentially_longer, attempts: 5

  rescue_from(GemNotFound, Gem::Package::FormatError, Gem::Security::Exception) do |error|
    version = version_arg.full_name
    logger.error "Storing gem contents for #{version} failed", error
    Rails.error.report error, context: { version: version }, handled: false
    raise error
  end

  def version_arg
    arguments.first[:version]
  end

  def perform(version:)
    raise VersionNotIndexed, "Version #{version&.full_name.inspect} is not indexed" unless version&.indexed?
    logger.info "Storing gem contents for #{version.full_name}"

    gem = RubygemFs.instance.get("gems/#{version.full_name}.gem")
    raise GemNotFound, "Gem file not found: #{version.full_name}.gem" unless gem

    package = Gem::Package.new(StringIO.new(gem))
    version.manifest.store_package package

    logger.info "Storing gem contents for #{version.full_name} succeeded"
  end
end

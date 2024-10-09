require "sigstore/verifier"
require "sigstore/rekor/client"
require "sigstore/models"
require "sigstore/policy"

module Sigstore::Loggable::ClassMethods
  undef_method :logger
  def logger
    @semantic_logger ||= SemanticLogger[self] # rubocop:disable Naming/MemoizedInstanceVariableName
  end
end

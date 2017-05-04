class Api::V2::DependenciesController < Api::V1::DependenciesController
  private

  def surrogate_key
    'dependencyapiv2'
  end

  def dependent_reader
    GemDependentV2
  end
end

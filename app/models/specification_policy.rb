class SpecificationPolicy < Gem::SpecificationPolicy
  def error(statement)
    return if statement.start_with?("#{Gem::SpecificationPolicy::LAZY} is not a")

    super
  end

  def warning(statement)
    # do nothing
  end
end

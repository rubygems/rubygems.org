Factory.define :requirement do |requirement|
  requirement.association(:version)
  requirement.association(:dependency)
end

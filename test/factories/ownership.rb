Factory.define :ownership do |ownership|
  ownership.association(:rubygem)
  ownership.association(:user)
end

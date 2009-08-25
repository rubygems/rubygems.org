Factory.define :subscription do |subscription|
  subscription.association(:rubygem)
  subscription.association(:user)
end

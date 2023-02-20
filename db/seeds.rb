users = 5.times.map do |x|
  User.create_with(
    handle: "user#{x}",
    password: SecureRandom.hex(10),
    twitter_username: "user#{x}",
    email_confirmed: true,
  ).find_or_create_by!(email: "user#{x}@example.com")
end

rubygem0 = Rubygem.find_or_create_by!(
  name: "rubygem0"
) do |rubygem|
  rubygem.ownerships.new(user: users[0], authorizer: users[0]).confirm!
end

rubygem1 = Rubygem.find_or_create_by!(
  name: "rubygem1"
) do |rubygem|
  rubygem.ownerships.new(user: users[0], authorizer: users[0]).confirm!
  rubygem.ownerships.new(user: users[2], authorizer: users[1]).confirm!
  rubygem.ownerships.new(user: users[3], authorizer: users[1])
end

Version.create_with(
  indexed: true,
  pusher: users[0]
).find_or_create_by!(rubygem: Rubygem.find_by!(name: "rubygem0"), number: "1.0.0",  platform: "ruby")
Version.create_with(
  indexed: true,
).find_or_create_by!(rubygem: Rubygem.find_by!(name: "rubygem0"), number: "1.0.0",  platform: "x86_64-darwin")

Version.create_with(
  indexed: true,
  pusher: users[0]
).find_or_create_by!(rubygem: Rubygem.find_by!(name: "rubygem1"), number: "1.0.0.pre.1",  platform: "ruby")
Version.create_with(
  indexed: true,
  pusher: users[1],
  dependencies: [Dependency.new(gem_dependency: Gem::Dependency.new("rubygem0", "~> 1.0.0"))]
).find_or_create_by!(rubygem: Rubygem.find_by!(name: "rubygem1"), number: "1.1.0.pre.2",  platform: "ruby")

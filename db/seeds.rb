password = "super-secret-password"

author = User.create_with(
  handle: "gem-author",
  password: password,
  email_confirmed: true
).find_or_create_by!(email: "gem-author@example.com")

maintainer = User.create_with(
  handle: "gem-maintainer",
  password: password,
  email_confirmed: true
).find_or_create_by!(email: "gem-maintainer@example.com")

user = User.create_with(
  handle: "gem-user",
  password: password,
  email_confirmed: true
).find_or_create_by!(email: "gem-user@example.com")

rubygem0 = Rubygem.find_or_create_by!(
  name: "rubygem0"
) do |rubygem|
  rubygem.ownerships.new(user: author, authorizer: author).confirm!
end

rubygem1 = Rubygem.find_or_create_by!(
  name: "rubygem1"
) do |rubygem|
  rubygem.ownerships.new(user: author, authorizer: author).confirm!
  rubygem.ownerships.new(user: maintainer, authorizer: author).confirm!
end

Version.create_with(
  indexed: true,
  pusher: author
).find_or_create_by!(rubygem: rubygem0, number: "1.0.0", platform: "ruby")
Version.create_with(
  indexed: true
).find_or_create_by!(rubygem: rubygem0, number: "1.0.0", platform: "x86_64-darwin")

Version.create_with(
  indexed: true,
  pusher: author
).find_or_create_by!(rubygem: rubygem1, number: "1.0.0.pre.1", platform: "ruby")
Version.create_with(
  indexed: true,
  pusher: maintainer,
  dependencies: [Dependency.new(gem_dependency: Gem::Dependency.new("rubygem0", "~> 1.0.0"))]
).find_or_create_by!(rubygem: rubygem1, number: "1.1.0.pre.2", platform: "ruby")

user.web_hooks.find_or_create_by!(url: "https://example.com/rubygem0", rubygem: rubygem0)
user.web_hooks.find_or_create_by!(url: "http://example.com/all", rubygem: nil)

puts <<~MESSAGE # rubocop:disable Rails/Output
  Three users  were created, you can login with following combinations:
    - email: #{author.email}, password: #{password} -> gem author owning few example gems
    - email: #{maintainer.email}, password: #{password} -> gem maintainer having push access to one author's example gem
    - email: #{user.email}, password: #{password} -> user with no gems
MESSAGE

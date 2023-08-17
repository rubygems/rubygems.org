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

requester = User.create_with(
  handle: "gem-requester",
  password: password,
  email_confirmed: true
).find_or_create_by!(email: "gem-requester@example.com")

User.create_with(
  email_confirmed: true,
  password:
).find_or_create_by!(email: "security@rubygems.org")

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

rubygem_requestable = Rubygem.find_or_create_by!(
  name: "rubygem_requestable"
) do |rubygem|
  rubygem.ownerships.new(user: author, authorizer: author).confirm!
end

rubygem_requestable.ownership_calls.create_with(
  note: "closed ownership call note!",
  status: :closed
).find_or_create_by!(user: author)
rubygem_requestable.ownership_calls.create_with(
  note: "open ownership call note!"
).find_or_create_by!(user: author)
rubygem_requestable.ownership_requests.create_with(
  note: "open ownership request"
).find_or_create_by!(ownership_call: rubygem_requestable.ownership_call, user: requester)

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
Version.create_with(
  indexed: false,
  pusher: author,
  yanked_at: Time.utc(2020, 3, 3)
).find_or_create_by!(rubygem: rubygem_requestable, number: "1.0.0", platform: "ruby")

user.web_hooks.find_or_create_by!(url: "https://example.com/rubygem0", rubygem: rubygem0)
user.web_hooks.find_or_create_by!(url: "http://example.com/all", rubygem: nil)

author.api_keys.find_or_create_by!(hashed_key: "securehashedkey", name: "api key", push_rubygem: true)

Admin::GitHubUser.create_with(
  is_admin: true,
  oauth_token: 'fake',
  info_data: {
  "viewer": {
    "name": "Rad Admin",
    "login": "rad_admin",
    "email": "rad_admin@rubygems.team",
    "avatarUrl": "/favicon.ico",
    "organization": {
      "login": "rubygems",
      "name": "RubyGems",
      "viewerIsAMember": true,
      "teams": {
        "edges": [
          {
            "node": {
              "name": "Infrastructure",
              "slug": "infrastructure"
            }
          },
          {
            "node": {
              "name": "Maintainers",
              "slug": "maintainers"
            }
          },
          {
            "node": {
              "name": "Monitoring",
              "slug": "monitoring"
            }
          },
          {
            "node": {
              "name": "RubyGems.org",
              "slug": "rubygems-org"
            }
          },
          {
            "node": {
              "name": "Rubygems.org Deployers",
              "slug": "rubygems-org-deployers"
            }
          },
          {
            "node": {
              "name": "Security",
              "slug": "security"
            }
          }
        ]
      }
    }
  }
}
).find_or_create_by!(github_id: "FAKE-rad_admin")

Admin::GitHubUser.create_with(
  is_admin: false,
  info_data: {
  "viewer": {
    "name": "Not An Admin",
    "login": "not_an_admin",
    "email": "not_an_admin@rubygems.team",
    "avatarUrl": "/favicon.ico",
    "organization": nil
  }
}
).find_or_create_by!(github_id: "FAKE-not_an_admin")

github_oidc_provider = OIDC::Provider
  .create_with(
    configuration: {
      issuer: "https://token.actions.githubusercontent.com",
      jwks_uri: "https://token.actions.githubusercontent.com/.well-known/jwks",
      response_types_supported: ["id_token"],
      subject_types_supported: ["public"],
      id_token_signing_alg_values_supported: ["RS256"],
      claims_supported: ["repo"]
    }
  ).find_or_create_by!(issuer: "https://token.actions.githubusercontent.com")

author_oidc_api_key_role = author.oidc_api_key_roles.create_with(
  api_key_permissions: {
    gems: ["rubygem0"],
    scopes: ["push_rubygem"],
    valid_for: "PT20M"
  },
  access_policy: {
    statements: [
      effect: "allow",
      principal: {
        oidc: "https://token.actions.githubusercontent.com"
      },
      conditions: [{
        operator: "string_equals",
        claim: "repo",
        value: "rubygems/rubygem0"
      }],
    ]
  }
).find_or_create_by!(
  name: "push-rubygem-1",
  provider: github_oidc_provider
)

author_oidc_api_key_role.user.api_keys.create_with(
  hashed_key: "expiredhashedkey",
  ownership: rubygem0.ownerships.find_by!(user: author),
  push_rubygem: true,
).find_or_create_by!(
  name: "push-rubygem-1-expired",
).tap do |api_key|
  OIDC::IdToken.find_or_create_by!(
    api_key:, 
    jwt: { claims: {jti: "expired"}, header: {}},
    api_key_role: author_oidc_api_key_role
  )
  api_key.touch(:expires_at, time: "2020-01-01T00:00:00Z")
end

author_oidc_api_key_role.user.api_keys.create_with(
  hashed_key: "unexpiredhashedkey",
  ownership: rubygem0.ownerships.find_by!(user: author),
  push_rubygem: true,
  expires_at: "2120-01-01T00:00:00Z"
).find_or_create_by!(
  name: "push-rubygem-1-unexpired",
).tap do |api_key|
  OIDC::IdToken.find_or_create_by!(
    api_key:, 
    jwt: { claims: {jti: "unexpired"}, header: {}},
    api_key_role: author_oidc_api_key_role
  )
end

author.api_keys.find_or_create_by!(
  user: author,
  hashed_key: "unexpiredmanualhashedkey",
  name: "Manual",
  push_rubygem: true,
)

puts <<~MESSAGE # rubocop:disable Rails/Output
  Four users were created, you can login with following combinations:
    - email: #{author.email}, password: #{password} -> gem author owning few example gems
    - email: #{maintainer.email}, password: #{password} -> gem maintainer having push access to one author's example gem
    - email: #{user.email}, password: #{password} -> user with no gems
    - email: #{requester.email}, password: #{password} -> user with an ownership request
MESSAGE

# frozen_string_literal: true

class Organization::Handle
  # Handles are compared without separators
  # ex "rubygems" reserves "ruby-gems" and "ruby_gems"
  def self.normalize(handle)
    handle.to_s.downcase.delete("-_")
  end

  RESTFUL_ACTIONS = %w[
    create
    destroy
    edit
    index
    new
    show
    update
  ].freeze

  # Path segments matching current routes
  # - not technically necessary but could be confusing in a world with top level orgs
  #   ex a private hosted gem repository as "www.rubygems.org/<org_handle>/gems/"
  ROUTES = %w[
    activity
    admin
    api
    api_key
    api_keys
    attestations
    compromised_password
    dashboard
    dependencies
    downloads
    email_confirmations
    gems
    info
    internal
    invitation
    invitations
    letter_opener
    lookbook
    members
    memberships
    multifactor_auth
    names
    news
    notifier
    oauth
    onboarding
    organization
    organizations
    owners
    pages
    password
    policies
    profile
    profiles
    releases
    search
    sendgrid_events
    session
    settings
    sign_in
    sign_out
    sign_up
    stats
    subscriptions
    teams
    totp
    trusted_publishers
    users
    versions
    webauthn_credentials
    webauthn_verification
  ].freeze

  # Served from public/ or by the asset pipeline, outside the Rails router.
  STATIC_PATHS = %w[
    assets
    favicon
    fonts
    images
    maintenance
    opensearch
    robots
    sponsors
    stylesheets
  ].freeze

  # Not routed yet. Cheap to hold now, expensive to reclaim from an org later.
  FUTURE_ROUTES = %w[
    about
    atom
    auth
    billing
    blog
    callback
    contact
    doc
    docs
    documentation
    explore
    feed
    graphql
    help
    invoices
    latest
    login
    logout
    notifications
    oidc
    plans
    popular
    pricing
    register
    rss
    saml
    sitemap
    sso
    status
    trending
    upload
    uploads
    webhook
    webhooks
  ].freeze

  # RubyGems.org and related entities
  REGISTRY_IDENTITY = %w[
    bundler
    gem
    gemcutter
    rubycentral
    rubyfoundation
    rubygem
    rubygems
    rubygemsadmin
    rubygemshelp
    rubygemsorg
    rubygemssecurity
    rubygemsstaff
    rubygemssupport
    rubygemsteam
    rubytogether
  ].freeze

  # The language and its implementation
  RUBY_CORE = %w[
    artichoke
    cruby
    irb
    jruby
    mjit
    mri
    mruby
    opal
    prism
    psych
    racc
    rake
    rbs
    rdoc
    rubinius
    ruby
    rubycore
    rubylang
    stdlib
    truffleruby
    yjit
    zjit
  ].freeze

  # Words that imply authority, endorsement, or a security role. Also covers
  # the RFC 2142 mailbox names, which matter if handles ever become
  # subdomains or email local-parts.
  TRUST_AND_SAFETY = %w[
    abuse
    administrator
    admins
    advisories
    advisory
    audit
    cert
    compliance
    copyright
    csirt
    cve
    disclosure
    dmca
    email
    gdpr
    helpdesk
    hostmaster
    incident
    legal
    mail
    mailer_daemon
    mod
    moderator
    moderators
    noreply
    official
    postmaster
    privacy
    root
    security
    smtp
    soc
    staff
    superuser
    support
    sysadmin
    terms
    tos
    trademark
    trust
    trusted
    trustedpublishing
    verification
    verified
    vulnerability
    webmaster
  ].freeze

  # Hostnames and environment names, for the case where a handle is ever
  # projected into DNS or used to address a deployment.
  INFRASTRUCTURE = %w[
    alpha
    backup
    beta
    canary
    cdn
    chat
    community
    dev
    development
    devops
    discord
    dns
    edge
    forum
    forums
    ftp
    gateway
    git
    health
    healthcheck
    infra
    irc
    local
    localhost
    matrix
    metrics
    mirror
    mirrors
    monitoring
    mx
    ns
    ns1
    ns2
    ops
    ping
    preview
    prod
    production
    proxy
    public
    qa
    sandbox
    slack
    sre
    stage
    staging
    static
    svn
    test
    testing
    uptime
    vpn
    wiki
    www
  ].freeze

  # Placeholder words that tend to break stuff or become confusing
  RESERVED_WORDS = %w[
    account
    accounts
    all
    anonymous
    app
    application
    apps
    bar
    baz
    bot
    bots
    config
    configuration
    current
    default
    everyone
    example
    examples
    false
    foo
    group
    groups
    guest
    licence
    license
    me
    my
    nan
    nil
    none
    null
    org
    organisation
    organisations
    orgs
    robot
    sample
    self
    service
    services
    system
    team
    this
    true
    undefined
    user
    void
  ].freeze

  RESERVED = [
    *FUTURE_ROUTES,
    *HELD_FOR_CLAIM
    *INFRASTRUCTURE,
    *REGISTRY_IDENTITY,
    *RESERVED_WORDS,
    *RESTFUL_ACTIONS,
    *ROUTES,
    *RUBY_CORE,
    *STATIC_PATHS,
    *TRUST_AND_SAFETY
  ].freeze

  # Indexed on the normalized form so lookups stay O(1) and every separator
  # spelling of a reserved name resolves to the same entry.
  NORMALIZED_RESERVED = RESERVED.to_set { |handle| normalize(handle) }.freeze

  def self.reserved?(handle)
    NORMALIZED_RESERVED.include?(normalize(handle))
  end
end

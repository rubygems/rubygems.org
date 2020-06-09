module Patterns
  extend ActiveSupport::Concern

  SPECIAL_CHARACTERS    = ".-_".freeze
  ALLOWED_CHARACTERS    = "[A-Za-z0-9#{Regexp.escape(SPECIAL_CHARACTERS)}]+".freeze
  ROUTE_PATTERN         = /#{ALLOWED_CHARACTERS}/.freeze
  LAZY_ROUTE_PATTERN    = /#{ALLOWED_CHARACTERS}?/.freeze
  NAME_PATTERN          = /\A#{ALLOWED_CHARACTERS}\Z/.freeze
  URL_VALIDATION_REGEXP = %r{\Ahttps?://([^\s:@]+:[^\s:@]*@)?[A-Za-z\d\-]+(\.[A-Za-z\d\-]+)+\.?(:\d{1,5})?([/?]\S*)?\z}.freeze
  GEM_NAME_BLACKLIST    = %w[
    abbrev
    base64
    cgi-session
    complex
    continuation
    coverage
    digest
    drb
    enumerator
    erb
    expect
    fiber
    find
    io-nonblock
    io-wait
    mkmf
    nkf
    open-uri
    optparse
    pathname
    pp
    prettyprint
    profiler
    pty
    rational
    rbconfig
    resolv
    resolv-replace
    rinda
    securerandom
    set
    shellwords
    socket
    syslog
    thread
    time
    tsort
    un
    unicode_normalize
    win32ole
    ubygems

    jruby
    mri
    mruby
    ruby
    rubygems
    install
    uninstall
    sidekiq-pro
    graphql-pro

    action-cable
    action_cable
    action-mailer
    action_mailer
    action-pack
    action_pack
    action-view
    action_view
    active-job
    active_job
    active-model
    active_model
    active-record
    active_record
    active-storage
    active_storage
    active-support
    active_support
    sprockets_rails
    rail-ties
    rail_ties
  ].freeze
end

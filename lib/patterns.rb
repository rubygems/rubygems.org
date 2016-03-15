module Patterns
  extend ActiveSupport::Concern

  SPECIAL_CHARACTERS = ".-_".freeze
  ALLOWED_CHARACTERS = "[A-Za-z0-9#{Regexp.escape(SPECIAL_CHARACTERS)}]+".freeze
  ROUTE_PATTERN      = /#{ALLOWED_CHARACTERS}/
  LAZY_ROUTE_PATTERN = /#{ALLOWED_CHARACTERS}?/
  NAME_PATTERN       = /\A#{ALLOWED_CHARACTERS}\Z/
  GEM_NAME_BLACKLIST = %w(
    abbrev
    base64
    benchmark
    bigdecimal
    cgi
    cgi-session
    cmath
    complex
    continuation
    coverage
    csv
    curses
    date
    delegate
    digest
    drb
    e2mmap
    english
    enumerator
    erb
    etc
    expect
    fcntl
    fiber
    fileutils
    find
    forwardable
    getoptlong
    gserver
    io-console
    io-nonblock
    io-wait
    ipaddr
    irb
    logger
    mathn
    matrix
    mkmf
    monitor
    mutex_m
    net-ftp
    net-http
    net-imap
    net-pop
    net-protocol
    net-smtp
    net-telnet
    nkf
    observer
    open-uri
    open3
    openssl
    optparse
    ostruct
    pathname
    prettyprint
    prime
    profile
    profiler
    pstore
    pty
    rational
    rbconfig
    resolv
    rexml
    rinda
    rss
    rubygems
    scanf
    securerandom
    set
    shellwords
    singleton
    socket
    stringio
    strscan
    syslog
    tempfile
    thread
    thwait
    time
    timeout
    tk
    tmpdir
    tsort
    un
    unicode_normalize
    uri
    weakref
    webrick
    win32ole
    yaml
    zlib
    ubygems
  ).freeze

  # see https://github.com/rubygems/rubygems.org/issues/1190
  if Time.zone.now > Time.zone.parse('2016-05-01 00:00:00') &&
      !GEM_NAME_BLACKLIST.include?('sync')
    warn "Sync gem should be back to the blacklist of game names by now."
  end
end

Gem::Specification.new do |s|
  s.name     = "daemons"
  s.version  = "1.0.12.4"
  s.date     = "2009-02-25"
  s.summary  = "A toolkit to convert your script to a controllable daemon (with Chris Kline's fix)"
  s.email    = "mikehale@gmail.com"
  s.homepage = "http://github.com/mikehale/daemons"
  s.description =<<EOF
    This is Daemons 1.0.10 with the addition of Chris Kline's fix from http://blog.rapleaf.com/dev/?p=19

    Includes ability to change the process uid/gid. Also logdir can be specified seperate from piddir.

    Daemons provides an easy way to wrap existing ruby scripts (for example a self-written server) to be run as a daemon and to be controlled by simple start/stop/restart commands.

    If you want, you can also use daemons to run blocks of ruby code in a daemon process and to control these processes from the main application.

    Besides this basic functionality, daemons offers many advanced features like exception backtracing and logging (in case your ruby script crashes) and monitoring and automatic restarting of your processes if they crash.

    Daemons includes the daemonize.rb script written by Travis Whitton to do the daemonization process.
EOF
  s.has_rdoc = false
  s.authors  = [
    "Michael Hale",
    "Thomas Uehlinger",
    "Travis Whitton",
    "Chris Kline"
    ]
  s.files    = [
    "daemons.gemspec",
    "lib/daemons/application.rb",
    "lib/daemons/application_group.rb",
    "lib/daemons/cmdline.rb",
    "lib/daemons/controller.rb",
    "lib/daemons/daemonize.rb",
    "lib/daemons/exceptions.rb",
    "lib/daemons/monitor.rb",
    "lib/daemons/pid.rb",
    "lib/daemons/pidfile.rb",
    "lib/daemons/pidmem.rb",
    "lib/daemons/etc_extension.rb",
    "lib/daemons/change_privilege.rb",
    "lib/daemons.rb",
    "LICENSE",
    "Rakefile",
    "README",
    "Releases",
    "TODO"
    ]
end

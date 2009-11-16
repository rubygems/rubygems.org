# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mikehale-daemons}
  s.version = "1.0.12.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Hale", "Thomas Uehlinger", "Travis Whitton", "Chris Kline"]
  s.date = %q{2009-02-25}
  s.description = %q{This is Daemons 1.0.10 with the addition of Chris Kline's fix from http://blog.rapleaf.com/dev/?p=19  Includes ability to change the process uid/gid. Also logdir can be specified seperate from piddir.  Daemons provides an easy way to wrap existing ruby scripts (for example a self-written server) to be run as a daemon and to be controlled by simple start/stop/restart commands.  If you want, you can also use daemons to run blocks of ruby code in a daemon process and to control these processes from the main application.  Besides this basic functionality, daemons offers many advanced features like exception backtracing and logging (in case your ruby script crashes) and monitoring and automatic restarting of your processes if they crash.  Daemons includes the daemonize.rb script written by Travis Whitton to do the daemonization process.}
  s.email = %q{mikehale@gmail.com}
  s.files = ["daemons.gemspec", "lib/daemons/application.rb", "lib/daemons/application_group.rb", "lib/daemons/cmdline.rb", "lib/daemons/controller.rb", "lib/daemons/daemonize.rb", "lib/daemons/exceptions.rb", "lib/daemons/monitor.rb", "lib/daemons/pid.rb", "lib/daemons/pidfile.rb", "lib/daemons/pidmem.rb", "lib/daemons/etc_extension.rb", "lib/daemons/change_privilege.rb", "lib/daemons.rb", "LICENSE", "Rakefile", "README", "Releases", "TODO"]
  s.has_rdoc = false
  s.homepage = %q{http://github.com/mikehale/daemons}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A toolkit to convert your script to a controllable daemon (with Chris Kline's fix)}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

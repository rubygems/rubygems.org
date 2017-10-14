require "rubygems"

# Assert we're using Psych
abort "ERROR! Use Psych for YAML, install libyaml and reinstall ruby" unless YAML == Psych

# Assert we have rubygems >= 2.6.14 for CVE-2017-0903
abort "ERROR! Use rubygems >= 2.6.14" unless Gem::Version.new(Gem::VERSION) >= Gem::Version.new("2.6.14")

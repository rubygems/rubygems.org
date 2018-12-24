# frozen_string_literal: true

# This patch ensures that we don't have a memory leak when instanciating
# Gem::Version.
#
# The way it is built and the purpose it is built for is for short lived uses
# (such as command line tools), but the ever growing hash [1] means that we
# never really clean this on a long lived web server.
#
# [1]: https://git.io/vHoxY
class Gem::Version
  def self.new(version)
    super
  end
end

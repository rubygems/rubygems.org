require 'rubygems'
require 'mini/test'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require '<%= require_name %>'

class Mini::Test::TestCase
end

Mini::Test.autorun

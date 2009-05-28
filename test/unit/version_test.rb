require File.dirname(__FILE__) + '/../test_helper'

class VersionTest < ActiveSupport::TestCase
  should_belong_to :rubygem
end

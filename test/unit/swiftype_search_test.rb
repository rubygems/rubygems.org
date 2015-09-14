require 'test_helper'

class SwiftypeSearchTest < ActiveSupport::TestCase
  
  context "to_st_hash" do
    setup do
      @rubygem = create(:rubygem, :name => "SomeGem")
      @version = create(:version, :rubygem => @rubygem)
    end

    should "create the hash with correct structure" do
      st_hash = @rubygem.to_st_hash
      st_hash.assert_valid_keys(:external_id, :fields)
      st_hash[:fields].each { |h| h.assert_valid_keys(:name, :value, :type) }
      name_values = st_hash[:fields].map { |a| a[:name] }
      assert_equal(name_values, ['name', 'authors', 'summary', 'version', 'downloads', 'url', 'description'])
    end
  end
end

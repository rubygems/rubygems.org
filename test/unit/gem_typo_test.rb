require 'test_helper'
require 'gem_typo'

class GemTypoTest < ActiveSupport::TestCase
  teardown do
    Rails.cache.clear
  end

  should 'return false for exact match' do
    gem_typo = GemTypo.new('rspec-core')
    assert_equal false, gem_typo.protected_typo?
  end

  should 'return true for 1 char distance match' do
    gem_typo = GemTypo.new('rspec-core2')
    assert_equal true, gem_typo.protected_typo?
  end

  should 'return false for 2 char distance match' do
    gem_typo = GemTypo.new('rspec-core12')
    assert_equal false, gem_typo.protected_typo?
  end

  should 'return false for 3 char distance match' do
    gem_typo = GemTypo.new('rspec-core123')
    assert_equal false, gem_typo.protected_typo?
  end

  should 'return false for 1 char distance match on the exception list' do
    gem_typo = GemTypo.new('rspec-coreZ')
    assert_equal false, gem_typo.protected_typo?
  end

  should 'allow customized protected_gems' do
    opts = {
      protected_gems: ["hello"]
    }

    gem_typo = GemTypo.new('hello', opts)
    assert_equal false, gem_typo.protected_typo?

    gem_typo = GemTypo.new('hello1', opts)
    assert_equal true, gem_typo.protected_typo?
  end

  should 'allow customized distance_threshold' do
    opts = {
      distance_threshold: 3
    }

    gem_typo = GemTypo.new('rack', opts)
    assert_equal false, gem_typo.protected_typo?

    gem_typo = GemTypo.new('rack1', opts)
    assert_equal true, gem_typo.protected_typo?

    gem_typo = GemTypo.new('rack12', opts)
    assert_equal true, gem_typo.protected_typo?

    gem_typo = GemTypo.new('rack123', opts)
    assert_equal true, gem_typo.protected_typo?

    gem_typo = GemTypo.new('rack1234', opts)
    assert_equal false, gem_typo.protected_typo?
  end

  should 'allow customized protected_gem_exceptions' do
    opts = {
      gem_exceptions: ["rake1"]
    }

    gem_typo = GemTypo.new('rake', opts)
    assert_equal false, gem_typo.protected_typo?

    gem_typo = GemTypo.new('rake1', opts)
    assert_equal false, gem_typo.protected_typo?
  end
end

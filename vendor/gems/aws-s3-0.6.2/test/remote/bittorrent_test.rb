require File.dirname(__FILE__) + '/test_helper'

class RemoteBittorrentTest < Test::Unit::TestCase
  def setup
    establish_real_connection
  end
  
  def teardown
    disconnect!
  end
  
  def test_bittorrent
    bt_test_key = 'testing-bittorrent'
    S3Object.create(bt_test_key, 'foo', TEST_BUCKET)
    
    # Confirm we can fetch a bittorrent file for this object
    
    torrent_file = nil
    assert_nothing_raised do
      torrent_file = S3Object.torrent_for(bt_test_key, TEST_BUCKET)
    end
    assert torrent_file
    assert torrent_file['tracker']
    
    # Make object accessible to the public via a torrent
    
    policy = S3Object.acl(bt_test_key, TEST_BUCKET)
    
    assert !policy.grants.include?(:public_read)
    
    assert_nothing_raised do
      S3Object.grant_torrent_access_to(bt_test_key, TEST_BUCKET)
    end
    
    policy = S3Object.acl(bt_test_key, TEST_BUCKET)
    
    assert policy.grants.include?(:public_read)
    
    # Confirm instance method wraps class method
    
    assert_equal torrent_file, S3Object.find(bt_test_key, TEST_BUCKET).torrent 
    
    S3Object.delete(bt_test_key, TEST_BUCKET)
  end
end
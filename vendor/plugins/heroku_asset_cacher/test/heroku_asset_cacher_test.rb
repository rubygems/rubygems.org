require 'test_helper'
require 'mocha'

class HerokuAssetPackagerTest < Test::Unit::TestCase
  def test_all_css_call
    env = {"REQUEST_PATH" => "/stylesheets/all.css"}

    app = mock()
    hac = HerokuAssetCacher.new(app)

    assert !$asset_cache_base_path.nil?
    hac.expects(:render_css)

    hac.call(env)
  end

  def test_all_js_call
    env = {"REQUEST_PATH" => "/javascripts/all.js"}

    app = mock()
    hac = HerokuAssetCacher.new(app)

    assert_equal false, $asset_cache_base_path.nil?
    hac.expects(:render_js)

    hac.call(env)
  end
  
  def test_regular_js_call
    env = {"REQUEST_PATH" => "/javascripts/test.js"}

    app = mock()
    app.expects(:call).with(env)
    hac = HerokuAssetCacher.new(app)
    
    hac.call(env)
  end
  
  def test_regular_css_call
    env = {"REQUEST_PATH" => "/stylesheets/test.css"}

    app = mock()
    app.expects(:call).with(env)
    hac = HerokuAssetCacher.new(app)
    
    hac.call(env)
  end
  
end
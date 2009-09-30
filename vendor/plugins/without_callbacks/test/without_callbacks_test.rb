require 'test/unit'
require 'test/lib/activerecord_test'

class WithoutCallbacksTest < ActiverecordTest

  def setup
    Fixtures.create_fixtures(FIXTURES_PTH, 'users')
  end

  def test_normal_behavior
    user = User.find(:first)
    assert_equal false, user.called_before_save?, "not working!!"
    assert_equal false, user.called_after_save?, "not working!!"
    user.save
    assert_equal true, user.called_before_save?, "before_save callback not called!!"
    assert_equal true, user.called_after_save?, "after_save callback not called!!"
  end
  
  def test_disable_by_symbol_method_name
    user = User.find(:first)
    assert_equal false, user.called_before_save?, "not working!!"
    assert_equal false, user.called_after_save?, "not working!!"
    User.without_callbacks(:do_stuff) do
      user.save
    end
    assert_equal false, user.called_before_save?, "before_save should not have been called!!"
    assert_equal true, user.called_after_save?, "after_save callback not called!!"
  end

  def test_disable_by_string_method_name
    user = User.find(:first)
    assert_equal false, user.called_before_save?, "not working!!"
    assert_equal false, user.called_after_save?, "not working!!"
    User.without_callbacks("do_stuff") do
      user.save
    end
    assert_equal false, user.called_before_save?, "before_save should not have been called!!"
    assert_equal true, user.called_after_save?, "after_save callback not called!!"
  end
  
  def test_disable_multiple_callbacks_by_symbol_method_name
    user = User.find(:first)
    assert_equal false, user.called_before_save?, "not working!!"
    assert_equal false, user.called_after_save?, "not working!!"
    User.without_callbacks(:do_stuff, :after_save) do
      user.save
    end
    assert_equal false, user.called_before_save?, "before_save should not have been called!!"
    assert_equal false, user.called_after_save?, "after_save should not have been called!!"
  end
  
  def test_disable_multiple_callbacks_by_string_method_name
    user = User.find(:first)
    assert_equal false, user.called_before_save?, "not working!!"
    assert_equal false, user.called_after_save?, "not working!!"
    User.without_callbacks("do_stuff", "after_save") do
      user.save
    end
    assert_equal false, user.called_before_save?, "before_save should not have been called!!"
    assert_equal false, user.called_after_save?, "after_save should not have been called!!"
  end
  
  def test_disable_multiple_callbacks_by_mixed_method_name
    user = User.find(:first)
    assert_equal false, user.called_before_save?, "not working!!"
    assert_equal false, user.called_after_save?, "not working!!"
    User.without_callbacks(:do_stuff, "after_save") do
      user.save
    end
    assert_equal false, user.called_before_save?, "before_save should not have been called!!"
    assert_equal false, user.called_after_save?, "after_save should not have been called!!"
  end
  
  def test_disable_all_callbacks
    user = User.find(:first)
    assert_equal false, user.called_before_save?, "not working!!"
    assert_equal false, user.called_after_save?, "not working!!"
    User.without_callbacks() do
      user.save
    end
    assert_equal false, user.called_before_save?, "before_save should not have been called!!"
    assert_equal false, user.called_after_save?, "after_save should not have been called!!"
  end
  
  def test_attempting_to_disable_undefined_method_should_throw_error
    user = User.find(:first)
    assert_raises(UndefinedMethodError) do
      User.without_callbacks("bogus_method") do
        user.save
      end
    end
  end
  
  def test_invalid_argument_should_raise_error
    user = User.find(:first)
    assert_raises(ArgumentError) do
      User.without_callbacks(1) do
        user.save
      end
    end
  end
  
end
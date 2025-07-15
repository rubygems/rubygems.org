module ExtendedTimeoutHelper
  DEFAULT_EXTENDED_WAIT_TIME = 5

  def self.included(base)
    base.setup :increase_wait_time
    base.teardown :restore_wait_time
  end

  def with_wait_time(seconds)
    @wait_time_override = seconds
  end

  private

  def increase_wait_time
    @original_wait_time = Capybara.default_max_wait_time
    wait_time = @wait_time_override || DEFAULT_EXTENDED_WAIT_TIME
    Capybara.default_max_wait_time = wait_time
  end

  def restore_wait_time
    Capybara.default_max_wait_time = @original_wait_time
    @wait_time_override = nil
  end
end

silence_warnings do
  Delayed::Job.const_set('MAX_ATTEMPTS', 3)
  Delayed::Job.const_set('MAX_RUN_TIME', 5.minutes)
end

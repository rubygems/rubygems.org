When 'the system processes jobs' do
  Delayed::Job.work_off
end


if defined?(Delayed::Job)
  Delayed::Job.class_eval do
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation
    
    if self.instance_methods.include?('name')
      add_transaction_tracer "invoke_job", :category => :task, :name => '#{self.name}'
    else
      add_transaction_tracer "invoke_job", :category => :task
    end
    
  end
end

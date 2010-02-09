# Hook in the notification to merb
error_notifier = Proc.new {
  if request.exceptions #check that there's actually an exception
    NewRelic::Agent.agent.error_collector.notice_error(request.exceptions.first, request, "#{params[:controller]}/#{params[:action]}", params)
  end
}
Merb::Dispatcher::DefaultException.before error_notifier
Exceptions.before error_notifier

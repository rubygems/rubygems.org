Honeybadger.exception_filter do |notice|
  !ActionDispatch::ExceptionWrapper.rescue_responses.keys.include? notice[:error_class]
end

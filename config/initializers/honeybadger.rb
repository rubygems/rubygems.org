Honeybadger.configure do |config|
  config.api_key = ENV['HONEYBADGER_API_KEY']
  config.unwrap_exceptions = false
  ActionDispatch::ExceptionWrapper.rescue_responses.keys.each do |error|
    config.ignore << error unless config.ignore.include? error
  end
end

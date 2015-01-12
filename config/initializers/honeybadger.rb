Honeybadger.configure do |config|
  config.api_key = ENV['HONEYBADGER_API_KEY']
  config.unwrap_exceptions = false
  config.ignore << "ActionDispatch::ParamsParser::ParseError"
end

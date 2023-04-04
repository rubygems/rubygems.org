Rails.application.configure do
  config.after_initialize do
    Timescaledb::Rails::ApplicationRecord.connects_to database: { writing: :downloads, reading: :downloads }
  end
end

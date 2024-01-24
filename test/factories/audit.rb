FactoryBot.define do
  factory :audit do
    admin_github_user

    comment { "A nice long comment" }
    action { "Admin Action" }
    auditable { association(:web_hook) }

    transient do
      records do
        {}
      end

      fields do
        { "field1" => "field1value", "field2" => %w[a b c] }
      end

      arguments do
        { "argument1" => true }
      end

      models do
        []
      end
    end

    after :create do |audit, options|
      audit.update(audited_changes: { records: options.records, fields: options.fields, arguments: options.arguments, models: options.models })
    end
  end
end

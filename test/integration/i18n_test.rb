require 'test_helper'

class I18nTest < ActionDispatch::IntegrationTest
  def collect_combined_keys(hash, ns = nil)
    hash.collect do |k, v|
      keys = []
      keys << collect_combined_keys(v, "#{ns}.#{k}") if v.is_a?(Hash)
      keys << "#{ns}.#{k}"
    end.flatten
  end

  test "translation consistency" do
    locales_path = File.expand_path('../../../config/locales', __FILE__)
    locales = Dir.glob("#{locales_path}/*.yml").collect do |file_path|
      File.basename(file_path, '.yml')
    end

    # collecting all locales
    locale_keys = {}
    locales.each do |locale|
      translations = YAML.load_file("#{locales_path}/#{locale}.yml")
      locale_keys[locale] = collect_combined_keys(translations[locale])
    end

    # Using en as reference
    reference = locale_keys[locales.delete('en')]
    assert reference.present?

    locale_keys.each do |locale, keys|
      missing = reference - keys
      assert missing.blank?, "#{locale} locale is missing: #{missing.join(', ')}"
      extra = keys - reference
      assert extra.blank?, "#{locale} locale has extra: #{extra.join(', ')}"
    end
  end
end

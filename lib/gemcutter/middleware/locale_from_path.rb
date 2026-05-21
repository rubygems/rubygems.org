# frozen_string_literal: true

module Gemcutter::Middleware
  class LocaleFromPath
    ENV_KEY = "rubygems.locale"
    ORIGINAL_PATH_INFO_KEY = "rubygems.original_path_info"

    def initialize(app)
      @app = app
    end

    def call(env)
      path_info = env["PATH_INFO"].to_s
      query_locale_path, query_string = extract_query_locale_path_from(path_info, env["QUERY_STRING"].to_s)

      return redirect_to(query_locale_path, query_string) if query_locale_path

      default_locale_path = extract_default_locale_path_from(path_info)

      return redirect_to(default_locale_path, env["QUERY_STRING"]) if default_locale_path

      locale, remainder = extract_locale_from(path_info)

      return @app.call(env) unless locale

      env[ENV_KEY] = locale
      env[ORIGINAL_PATH_INFO_KEY] = path_info

      env["SCRIPT_NAME"] = "/#{locale}"
      env["PATH_INFO"] = remainder

      @app.call(env)
    end

    private

    def extract_query_locale_path_from(path_info, query_string)
      query_params = Rack::Utils.parse_nested_query(query_string)
      return unless query_params.key?("locale")

      locale = query_params.delete("locale").to_s
      path = query_locale_path(locale, path_info)

      [path, query_params.to_query]
    end

    def query_locale_path(locale, path_info)
      path = path_without_locale_prefix(path_info)
      return path if locale == I18n.default_locale.to_s
      return locale_path(locale, path) if non_default_locales.include?(locale)

      path_info
    end

    def path_without_locale_prefix(path_info)
      extract_default_locale_path_from(path_info) || extract_locale_from(path_info)&.second || path_info
    end

    def locale_path(locale, path)
      path == "/" ? "/#{locale}" : "/#{locale}#{path}"
    end

    def extract_default_locale_path_from(path_info)
      match = path_info.match(default_locale_path_pattern)
      return unless match

      match[:remainder].presence || "/"
    end

    def extract_locale_from(path_info)
      match = path_info.match(locale_path_pattern)
      return unless match

      locale = match[:locale]
      remainder = match[:remainder].presence || "/"

      [locale, remainder]
    end

    def default_locale_path_pattern
      @default_locale_path_pattern ||= %r{\A/#{Regexp.escape(I18n.default_locale.to_s)}(?<remainder>/.*)?\z}
    end

    def locale_path_pattern
      @locale_path_pattern ||= begin
        locales = non_default_locales.map { |locale| Regexp.escape(locale) }.join("|")
        %r{\A/(?<locale>#{locales})(?<remainder>/.*)?\z}
      end
    end

    def non_default_locales
      I18n.available_locales.map(&:to_s) - [I18n.default_locale.to_s]
    end

    def redirect_to(path, query_string)
      location = path
      location = "#{location}?#{query_string}" if query_string.present?

      [301, { "Location" => location }, []]
    end
  end
end

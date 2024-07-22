# frozen_string_literal: true

require "importmap/packager"

module ImportmapHelper
  VerifyError = Class.new(StandardError)

  class Packager < Importmap::Packager
    self.endpoint = URI("https://api.jspm.io/generate")

    # Copied from https://github.com/rails/importmap-rails/pull/237
    def verify(package, url)
      ensure_vendor_directory_exists

      return unless vendored_package_path(package).file?
      verify_vendored_package(package, url)
    end

    def verify_vendored_package(package, url)
      vendored_body = vendored_package_path(package).read.strip
      remote_body = load_package_file(package, url).strip

      return true if vendored_body == remote_body

      raise ImportmapHelper::VerifyError, "Vendored #{package}#{extract_package_version_from(url)} does not match remote #{url}"
    end

    def load_package_file(package, url)
      response = Net::HTTP.get_response(URI(url))

      if response.code == "200"
        format_vendored_package(package, url, response.body)
      else
        handle_failure_response(response)
      end
    end

    def format_vendored_package(package, url, source)
      formatted = +""
      if Gem::Version.new(Importmap::VERSION) > Gem::Version.new("2.0.1")
        formatted.concat "// #{package}#{extract_package_version_from(url)} downloaded from #{url}\n\n"
      end
      formatted.concat remove_sourcemap_comment_from(source).force_encoding("UTF-8")
      formatted
    end

    def save_vendored_package(package, _url, source)
      File.write(vendored_package_path(package), source)
    end

    public :vendored_package_path
  end
end

# frozen_string_literal: true

require "importmap/packager"

module ImportmapHelper
  VerifyError = Class.new(StandardError)

  class Packager < Importmap::Packager
    self.endpoint = URI("https://api.jspm.io/generate")

    # Copied from https://github.com/rails/importmap-rails/pull/237
    def verify(package, url, verbose: false)
      ensure_vendor_directory_exists

      unless vendored_package_path(package).file?
        raise ImportmapHelper::VerifyError, "Pinned #{package}#{extract_package_version_from(url)} does not exist in vendor/javascript"
      end
      verify_vendored_package(package, url, verbose:)
    end

    def verify_vendored_package(package, url, verbose: false)
      vendored_body = vendored_package_path(package).read.strip
      vendored_body = vendored_body.lines[2..].join if vendored_body.start_with?("//") # remove the importmap-rails comment
      remote_body = load_package_file(url).strip

      return true if vendored_body == remote_body

      verbose_error = verbose ? verbose_diff(remote_body, vendored_body) : " (run with VERBOSE=true for diff)"
      raise ImportmapHelper::VerifyError, "Vendored #{package}#{extract_package_version_from(url)} does not match remote #{url}#{verbose_error}"
    end

    def load_package_file(url)
      response = Net::HTTP.get_response(URI(url))

      if response.code == "200"
        format_vendored_package(response.body)
      else
        handle_failure_response(response)
      end
    end

    def format_vendored_package(source)
      remove_sourcemap_comment_from(source).force_encoding("UTF-8")
    end

    def save_vendored_package(package, url, source)
      File.open(vendored_package_path(package), "w+") do |vendored_package|
        vendored_package.write "// #{package}#{extract_package_version_from(url)} downloaded from #{url}\n\n"

        vendored_package.write remove_sourcemap_comment_from(source).force_encoding("UTF-8")
      end
    end

    def verbose_diff(remote_body, vendored_body)
      require "diff/lcs"
      diffs = Diff::LCS.sdiff(remote_body.split("\n"), vendored_body.split("\n"))
      out = "\n\nDiff:\n- Remote\n+ Vendored\n\n"
      out + diffs.map do |diff|
        case diff.action
        when "-" then "- #{diff.old_element}"
        when "!" then "- #{diff.old_element}\n+ #{diff.new_element}"
        when "+" then "+ #{diff.new_element}"
        when "=" then "  #{diff.old_element}"
        end
      end.join("\n")
    end

    public :vendored_package_path
  end
end

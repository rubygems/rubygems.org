# frozen_string_literal: true

require "importmap/npm"
require "tasks/helpers/importmap_helper"

namespace :importmap do
  desc "Verify downloaded packages in vendor/javascript"
  task :verify do # rubocop:disable Rails/RakeEnvironment
    options = { env: "production", from: "jspm.io" }
    importmap_path = "config/importmap.rb"
    vendor_pathname = Rails.root.join("vendor/javascript")
    all_files = vendor_pathname.glob("*.js").map { |p| p.relative_path_from(Rails.root) }
    manually_vendored_files = ["github-buttons.js", "webauthn-json.js"]

    manually_vendored_files.each do |filename|
      path = vendor_pathname.join(filename).relative_path_from(Rails.root)
      all_files.delete(path) || raise("importmap:verify expected #{path} not found")
    end

    npm = Importmap::Npm.new(importmap_path)

    packages = npm.packages_with_versions.map do |p, v|
      v.blank? ? p : [p, v].join("@")
    end

    puts "Verifying packages in vendor/javascript"

    packager = ImportmapHelper::Packager.new(
      importmap_path,
      vendor_path: vendor_pathname.relative_path_from(Rails.root)
    )

    if (imports = packager.import(*packages, **options))
      imports.each do |package, url|
        puts %(Verifying "#{package}" download from #{url})
        packager.verify(package, url, verbose: ENV["VERBOSE"])
        path = packager.vendored_package_path(package)
        puts %(Verified  "#{package}" at #{path})
        all_files.delete path
      end

      if all_files.empty?
        puts "All pinned js in vendor/javascript verified."
      else
        puts "Remaining files in vendor not verified:"
        # ignore known manually vendored files or raise if they get deleted without updating the task

        all_files.each do |f|
          puts " - #{f}"
        end
        exit 1
      end
    else
      warn "No packages found"
      exit 1
    end
  end

  desc "Re-download all packages in the importmap with the same versions"
  task pristine: :environment do
    options = { env: "production", from: "jspm.io" }
    npm = Importmap::Npm.new(Rails.root.join("config/importmap.rb"))

    packages = npm.packages_with_versions.map do |p, v|
      v.blank? ? p : [p, v].join("@")
    end

    puts "Downloading pristine packages from #{options[:from]} to vendor/javascript"

    packager = ImportmapHelper::Packager.new

    if (imports = packager.import(*packages, env: options[:env], from: options[:from]))
      imports.each do |package, url|
        puts %(Downloading pinned "#{package}" to #{packager.vendor_path}/#{package}.js from #{url})
        packager.download(package, url)
      end
    else
      puts "Couldn't find any packages in #{packages.inspect} on #{options[:from]}"
    end
  end
end

# frozen_string_literal: true

# Schema that describes most gemspecs
module GemValidator::Schema # rubocop:disable Metrics/ModuleLength
  VALID_URI_PATTERN = %r{\Ahttps?://([^\s:@]+:[^\s:@]*@)?[A-Za-z\d-]+(\.[A-Za-z\d-]+)+\.?(:\d{1,5})?([/?]\S*)?\z}
  VALID_VERSION_PATTERN = /\A([0-9]+(?>\.[0-9a-zA-Z]+)*(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?)?\z/

  METADATA_LINK = {
    "type" => "string",
    "pattern" => VALID_URI_PATTERN,
    "maxLength" => 1024
  }.freeze

  VERSION = {
    "type" => "object",
    "tag" => "!ruby/object:Gem::Version",
    "properties" => {
      "version" => {
        "type" => "string",
        "pattern" => VALID_VERSION_PATTERN
      }
    },
    "required" => ["version"]
  }.freeze

  REQUIREMENT = {
    "type" => %w[null object],
    "tag" => "!ruby/object:Gem::Requirement",
    "properties" => {
      "requirements" => {
        "type" => "array",
        "items" => {
          "type" => "array",
          "prefixItems" => [
            { "type" => "string" },
            VERSION
          ]
        }
      },
      "version" => { "type" => "null" }, # version 2 "10to1-crack" gem
      "none" => { "type" => "boolean" } # from "0xffffff" gem
    }
  }.freeze

  DEPENDENCY = {
    "type" => "object",
    "tag" => "!ruby/object:Gem::Dependency",
    "properties" => {
      "name" => { "type" => %w[string array], "items" => { "type" => "string" } }, # bstack_wrapper-0.0.4
      "type" => {
        "type" => "symbol",
        "pattern" => /\A:(?:development|runtime)\z/
      },
      "prerelease" => { "type" => "boolean" },
      "requirement" => REQUIREMENT,
      "version_requirements" => REQUIREMENT,

      "version_requirement" => { "type" => "null" }, # 16watts-fluently-0.3.1 gem

      "force_ruby_platform" => { "type" => "boolean" } # aikido-zen-0.2.0
    }
  }.freeze

  SPECIFICATION = Ractor.make_shareable(
    {
      "type" => "object",
      "tag" => "!ruby/object:Gem::Specification",
      "properties" => {
        "name" => {
          "type" => "string",
          "pattern" => /\A(?=.*[a-zA-Z])[a-zA-Z0-9][a-zA-Z0-9._-]*\z/
        },
        "version" => VERSION,
        "platform" => { "type" => %w[string null] },
        "authors" => {
          "type" => "array",
          "items" => {
            "type" => ["string"],
            "items" => { "type" => "string" }
          },
          "minItems" => 1
        }, # evil-ruby-0.1.0 has a null entry, fresh_cookies-1.0.0 has an array of arrays of strings
        "autorequire" => {
          "type" => %w[null string array boolean],
            "items" => { "type" => "string" }
        }, # capistrano-strategy-copy-working-dir boolean autorequire
        "bindir" => { "type" => %w[string array boolean null], "items" => { "type" => "string" } }, # boolean from arika-ruby-termios
        "cert_chain" => { "type" => %w[null array], "items" => { "type" => "string" } },
        "date" => {
          "type" => %w[date time],
          "pattern" => /\A\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])/
        },
        "dependencies" => {
          "type" => %w[array null], # erdgeist-chaos_calendar-0.1.2 has null deps
          "items" => DEPENDENCY
        },
        "description" => { "type" => %w[string null] },
        "email" => {
          "type" => %w[array string null],
          "items" => {
            "type" => %w[string null array],
            "items" => { "type" => "string" }
          }
        }, # befog-0.5.3, list of null email, Buranya-0.7.1 list of list of email
        "executables" => {
          "type" => %w[array null],
          "items" => {
            "type" => %w[string array],
            "items" => { "type" => "string" }
          }
        }, # jack_gem-0.0.3 has an array of arrays
        "extensions" => { "type" => %w[array null], "items" => { "type" => "string" } },
        "extra_rdoc_files" => { "type" => %w[array null], "items" => { "type" => "string" } },
        "files" => { "type" => "array", "items" => { "type" => "string" } },
        "homepage" => { "type" => %w[string null] },
        "licenses" => {
          "type" => ["array"],
          "items" => {
            "type" => %w[null string],
            "maxLength" => 64
          }
        },
        "metadata" => {
          "type" => "object",
          "properties" => {
            "homepage_uri" => METADATA_LINK,
            "changelog_uri" => METADATA_LINK,
            "source_code_uri" => METADATA_LINK,
            "documentation_uri" => METADATA_LINK,
            "wiki_uri" => METADATA_LINK,
            "mailing_list_uri" => METADATA_LINK,
            "bug_tracker_uri" => METADATA_LINK,
            "download_uri" => METADATA_LINK,
            "funding_uri" => METADATA_LINK
          },
          "propertyNames" => {
            "maxLength" => 128
          },
          "additionalProperties" => {
            "type" => "string",
            "maxLength" => 1024
          }
        },
        "post_install_message" => {
          "type" => %w[null boolean string array],
          "items" => { "type" => "string" } # fisheye-crucible-0.0.2.gem  has a list of strings
        },
        "rdoc_options" => {
          "type" => %w[array null],
          "items" => {
            "type" => %w[string array],
            "items" => { "type" => "string" }
          }
        },
        "require_paths" => {
          "type" => %w[array string null],
          "items" => {
            "type" => %w[string array],
            "items" => { "type" => "string" }
          }
        },
        "required_ruby_version" => REQUIREMENT,
        "required_rubygems_version" => REQUIREMENT,
        "requirements" => {
          "type" => %w[array null],
          "items" => {
            "type" => %w[string array object], # sprout-flexunitsrc-library-0.85.1.gem has a hash, 2008-02-10 00:00:00 -08:00
            "items" => { "type" => "string" }
          }
        }, # core_image-0.0.3.5.gem
        "rubygems_version" => { "type" => "string" },
        "signing_key" => { "type" => "null" },
        "specification_version" => { "type" => "integer" },
        "summary" => { "type" => %w[string null] },
        "test_files" => { "type" => %w[array null], "items" => { "type" => "string" } },
        "original_platform" => { "type" => "string" },
        "rubyforge_project" => {
          "type" => %w[string null array],
          "items" => { "type" => "string" } # 2012-09-11 00:00:00.000000000 Z, sinatra-filler-1.0.0 has an array
        }, # spec version 3
        "default_executable" => {
          "type" => %w[null string array],
          "items" => { "type" => "string" }
        }, # spec version 3, cloudcrypt-0.0.9.gem has an array for default executable
        "has_rdoc" => { "type" => %w[boolean null string] }, # spec version 3 acts_as_xlsx-1.0.6
        "author" => { "type" => %w[string null] }, # spec version not specified, an-app-0.0.3
        "engine_dependencies" => { "type" => "object", "items" => { "type" => "string" } }, # deals_with-0.0.6
        "extensions_fallback" => { "type" => "null" }, # opod-0.0.1
        "source" => { "type" => "null" } # 2009-10-13 00:00:00 +02:00, rack-uploads-0.2.1
      },
      "required" => %w[name version summary authors]
    }
  ).freeze

  # Schema for checksums.yaml
  # Since RubyGems 3.2.0, the only possible checksums are SHA256 and SHA512
  CHECKSUM_OBJECT = {
    "type" => "object",
    "properties" => {
      "metadata.gz" => { "type" => "string" },
      "metadata" => { "type" => "string" },
      "data.tar.gz" => { "type" => "string" }
    }
  }.freeze

  CHECKSUMS = Ractor.make_shareable(
    {
      "type" => "object",
      "properties" => {
        "SHA256" => CHECKSUM_OBJECT,
        "SHA512" => CHECKSUM_OBJECT
      },
      "required" => ["SHA256"],
      "additionalProperties" => CHECKSUM_OBJECT
    }
  ).freeze
end

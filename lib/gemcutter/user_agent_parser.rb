class Gemcutter::UserAgentParser
  class UnableToParse < ArgumentError; end
  class MultipleParsersMatched < ArgumentError; end

  class Set
    include SemanticLogger::Loggable

    def initialize
      logger
      @parsers = []
    end

    def register(parser)
      @parsers << parser
      parser
    end

    def call(user_agent, exclusive: false)
      ret = nil
      @parsers.each do |parser|
        res = parser.call(user_agent)
        return res unless exclusive
        raise MultipleParsersMatched, "Multiple parsers matched #{user_agent.inspect}" if ret
        ret = res
      rescue UnableToParse
        next
      rescue MultipleParsersMatched
        raise
      rescue StandardError => e
        logger.error("Error parsing user agent: #{e.message}", user_agent:, parser: parser.name, error: e)
        next
      end

      return ret if ret

      raise UnableToParse, "No parser could parse the user agent"
    end
  end

  class RegexUserAgentParser < Gemcutter::UserAgentParser
    attr_reader :name

    def initialize(regexes, handler, name: nil)
      super()

      @name = name || handler.name
      @regexes = regexes
      @handler = handler
    end

    def call(user_agent)
      @regexes.each do |regex|
        next unless (match = regex.match(user_agent))
        group_to_name = match.regexp.named_captures.transform_values(&:sole).invert.transform_values(&:to_sym)
        args = []
        kwargs = {}
        match.to_a.each_with_index do |value, group|
          next if group.zero?
          if (name = group_to_name[group])
            kwargs[name] = value
          else
            args << value
          end
        end
        return @handler.call(*args, **kwargs)
      end
      raise UnableToParse
    end
  end

  SET = Set.new

  def self.register(parser)
    SET.register(parser)
  end

  def self.regex_ua_parser(*regexps, method)
    RegexUserAgentParser.new(regexps, method(method))
  end

  register regex_ua_parser \
    %r{^
     (
         Mozilla |
         Safari |
         wget |
         curl |
         Opera |
         aria2 |
         AndroidDownloadManager |
         com\.apple\.WebKit\.Networking/ |
         FDM\ \S+ |
         URL/Emacs |
         Firefox/ |
         UCWEB |
         Links |
         ^okhttp |
         ^Apache-HttpClient
     )
     (/|$)(.*)}ix,
  def self.browser_user_agent(*parts)
    ua = USER_AGENT_PARSER.parse(parts.join)
    Events::UserAgentInfo.new(installer: "Browser", device: ua.device&.family, os: ua.os&.family, user_agent: ua.family)
  end
  USER_AGENT_PARSER = UserAgentParser::Parser.new.freeze

  register regex_ua_parser \
    %r{\A
      bundler/(?<bundler>[0-9a-zA-Z.-]+)
      [ ]rubygems/(?<rubygems>[0-9a-zA-Z.-]+)
      [ ]ruby/(?<ruby>[0-9a-zA-Z.-]+)
      [ ]\((?<platform>[^)]*)\)
      [ ]command/(?<command>.*?)
      (?:[ ]jruby/(?<jruby>[0-9a-zA-Z.-]+))?
      (?:[ ]truffleruby/(?<truffleruby>[0-9a-zA-Z.-]+))?
      (?:[ ]options/(?<options>.*?))?
      (?:[ ]ci/(?<ci>.*?))?
      [ ](?<execution_id>[a-f0-9]{16})
      (?:[ ]Gemstash/(?<gemstash>[0-9a-zA-Z.-]+))?
      \z
    }ux,
  def self.bundler_user_agent(platform:, jruby:, truffleruby:, **)
    implementation = "Ruby"
    implementation = "JRuby" if jruby
    implementation = "TruffleRuby" if truffleruby

    Events::UserAgentInfo.new(installer: "Bundler", system: platform, implementation:)
  end

  register regex_ua_parser \
    %r{\A
      (?:Ruby,[ ])?
      RubyGems/(?<rubygems>[0-9a-z.-]+)[ ]
      (?<platform>.*)[ ]
      Ruby/(?<ruby>[0-9a-z.-]+)[ ]
      \(.*?\)
      (?:[ ](?<ruby_engine>jruby|truffleruby|rbx))?
      (?:[ ]Gemstash/(?<gemstash>[0-9a-z.-]+))?
      \z}x,
      /\ARuby, Gems (?<rubygems>[0-9a-z.-]+)\z/,
  def self.rubygems_user_agent(platform: nil, ruby_engine: nil, **)
    Events::UserAgentInfo.new(installer: "RubyGems", system: platform, implementation: ruby_engine&.capitalize || "Ruby")
  end

  SET.freeze

  def self.call(...)
    SET.call(...)
  end
end

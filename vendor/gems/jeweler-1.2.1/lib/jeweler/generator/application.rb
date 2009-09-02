class Jeweler
  class Generator
    class Application
      class << self
        def run!(*arguments)
          env_opts = if ENV['JEWELER_OPTS']
            Jeweler::Generator::Options.new(ENV['JEWELER_OPTS'].split(' '))
          end
          options = Jeweler::Generator::Options.new(arguments)
          options = options.merge(env_opts) if env_opts

          if options[:invalid_argument]
            $stderr.puts options[:invalid_argument]
            options[:show_help] = true
          end

          if options[:show_help]
            $stderr.puts options.opts
            return 1
          end

          unless arguments.size == 1
            $stderr.puts options.opts
            return 1
          end

          project_name = arguments.first

          begin
            generator = Jeweler::Generator.new(project_name, options)
            generator.run
            return 0
          rescue Jeweler::NoGitUserName
            $stderr.puts %Q{No user.name found in ~/.gitconfig. Please tell git about yourself (see http://github.com/guides/tell-git-your-user-name-and-email-address for details). For example: git config --global user.name "mad voo"}
            return 1
          rescue Jeweler::NoGitUserEmail
            $stderr.puts %Q{No user.email found in ~/.gitconfig. Please tell git about yourself (see http://github.com/guides/tell-git-your-user-name-and-email-address for details). For example: git config --global user.email mad.vooo@gmail.com}
            return 1
          rescue Jeweler::NoGitHubUser
            $stderr.puts %Q{No github.user found in ~/.gitconfig. Please tell git about your GitHub account (see http://github.com/blog/180-local-github-config for details). For example: git config --global github.user defunkt}
            return 1
          rescue Jeweler::NoGitHubToken
            $stderr.puts %Q{No github.token found in ~/.gitconfig. Please tell git about your GitHub account (see http://github.com/blog/180-local-github-config for details). For example: git config --global github.token 6ef8395fecf207165f1a82178ae1b984}
            return 1
          rescue Jeweler::FileInTheWay
            $stderr.puts "The directory #{project_name} already exists. Maybe move it out of the way before continuing?"
            return 1
          end
        end
      end

    end
  end
end

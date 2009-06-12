module Ginger
  module Kernel
    def self.included(base)
      base.class_eval do
        def require_with_ginger(req)
          unless scenario = ginger_scenario
            require_without_ginger(req)
            return
          end
          
          if scenario.version(req)
            gem ginger_gem_name(req)
          end
          
          require_without_ginger(req)
        end

        alias_method :require_without_ginger, :require
        alias_method :require, :require_with_ginger
        
        def gem_with_ginger(gem_name, *version_requirements)
          unless scenario = ginger_scenario
            gem_without_ginger(gem_name, *version_requirements)
            return
          end
          
          if version_requirements.length == 0 &&
             version = scenario.version(gem_name)
            version_requirements << "= #{version}"
          end
          
          gem_without_ginger(gem_name, *version_requirements)
        end
        
        alias_method :gem_without_ginger, :gem
        alias_method :gem, :gem_with_ginger
        
        private
        
        def ginger_scenario
          return nil unless File.exists?(".ginger")
          
          scenario = nil
          File.open('.ginger') { |f| scenario = f.read }
          return nil unless scenario
          
          Ginger::Configuration.instance.scenarios[scenario.to_i]
        end
        
        def ginger_gem_name(gem_name)
          Ginger::Configuration.instance.aliases[gem_name] || gem_name
        end
      end
    end
  end
end
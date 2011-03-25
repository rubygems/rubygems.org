require 'graphviz'
class DependencyGraph
  attr_reader :graph

  def initialize(rubygem, version = nil)
    @graph = GraphViz.new(rubygem.full_name, {:type => :digraph, :concentrate => true, :normalize=> true,:bgcolor => '#EBE3D6', :center => true})
    @graph.edge["decorate"] = true;
    build(rubygem.name, nil, rubygem.version)
  end

  protected

  def build(rubygem, parent = nil, version = nil)
    node = @graph.add_node(rubygem, :URL => "http://#{$rubygems_config[:host]}/gems/#{rubygem}", :penwidth => 2)
    if parent
      @graph.add_edge(parent, node)
    else
      node.set {|n| n.fontcolor = '#AA0000'}
    end
    node['target'] = '_blank'
    deps = Dependency.for([rubygem])
    dep = deps.detect {|d| d[:number] == version.to_s}
    dep[:dependencies].each do |gem|
      ver = Dependency.for(gem.first)
      ver = ver.map{|v| v[:number]}
      build(gem.first, node, match_version(ver, version))
    end if dep
  end

  def match_version(versions, dependency)
    dependency = Gem::Requirement.new(dependency)
    versions.last.tap do |version|
      versions.each do |dep_version|
        ver = Gem::Version.new(dep_version[:number])
        dependency.satisfied_by?(ver) or next
        if version < ver
          if dependency.prerelease?
            version = dep_version
          else
            version = dep_version unless ver.prerelease?
          end
        end
      end
    end
  end
end

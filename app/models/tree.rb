class Tree < ActiveRecord::Base

  belongs_to :version

  def tmpdir
    "/tmp/#{self.id}"
  end

  def create_tmpdir
    FileUtils.mkdir_p tmpdir
  end

  def name
    version.rubygem.name
  end

  def number
    version.number
  end

  def gemfile_string
    %[source 'https://rubygems.org'\ngem '#{name}', '#{number}']
  end

  def gemfile_path
    "#{tmpdir}/Gemfile"
  end

  def data_path
    "#{tmpdir}/data.json"
  end

  def write_gemfile
    create_tmpdir
    File.open(gemfile_path, 'w') {|f| f.write(gemfile_string) }
  end

  def set_tree_data
    self.tree_data = translate_specs.to_json
  end

  # This method shells out to a simple script to bust
  # out of the bundler jail that is imposed by runing
  # inside of the main rails app.
  def capture_specs
    Bundler.with_clean_env do
      command = "#{Rails.root}/script/capture_specs.rb"
      system command
    end
    self.data = File.open(data_path).read
  end

  
  def prep_data
    write_gemfile
    current_dir = Dir.pwd
    Dir.chdir tmpdir
    
    self.capture_specs
    self.set_tree_data
    self.state = 'ready'
    self.save

  rescue Errno::ENOENT => e
    # This happens if bundler is unable to resolve.
    # This should buble up for error reporting.
    # Maybe it should be queued for retry?
    self.state = "error"
    self.save
    raise e
  ensure
    cleanup
    Dir.chdir current_dir
  end

  def data_json
    JSON(data)
  end

  def keyed_specs
    specs = {}
    data_json.each do |d|
      specs[d['name']] = d
    end
    specs
  end

  def translate_specs
    weights = {:runtime => [],:development => []}
    tree = build_tree(self.name,self.number,'',keyed_specs,weights)
    self.runtime_weight = weights[:runtime].uniq.size
    self.development_weight = weights[:development].uniq.size
    tree
  end

  def build_tree(gem_name,requirement,type,spec_data,weights,already_included = [])
    data = {
      :name => gem_name,
      :requirement => requirement,
      :type => type,
      :version => nil
    }
    unless type.blank?
      weights[type.to_sym].push gem_name
    end
    spec = spec_data[gem_name]
    if spec.nil?
      # This happens for development deps of dependent gems.
      # Since they wouldn't show up in Gemfile.lock for the 
      # single gem, we don't care about them.
      return data
    end
    data[:version] = spec['version']
    already_included << gem_name
    children = []
    spec['dependencies'].each do |dep|
      next if already_included.include? dep['name']
      #next if dep['type'] == 'development'
      children.push build_tree(dep['name'],dep['requirement'],dep['type'],spec_data,weights,already_included)
    end
    data[:children] = children
    data
  end

  def cleanup
    FileUtils.rm_r tmpdir
  end

end

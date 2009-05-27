class ViewGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.directory File.join('app/views', class_path, file_name)

      # View template for specified action.
      if actions.include?("new")
        path = File.join('app/views', class_path, file_name, "new.html.erb")
        m.template 'view_new.html.erb', path,
          :assigns => { :action => action, :path => path }
      end
    end
  end
end

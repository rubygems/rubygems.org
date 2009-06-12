# Copyright (c) 2008 Michael Hartl, released under the MIT license
# http://github.com/mhartl/find_mass_assignment

require 'active_support'
 
# Find potential mass assignment problems.
# The method is to scan the controllers for likely mass assignment,
# and then find the corresponding models that *don't* have
# attr_accessible defined. Any time that happens, it's a potential problem.
 
class String
  
  @@cache = {}
  
  # A regex to match likely cases of mass assignment
  # Examples of matching strings:
  # "Foo.new( { :bar => 'baz' } )"
  # "Foo.update_attributes!(params[:foo])"
  MASS_ASSIGNMENT = /(\w+)\.(new|create|update_attributes|build)!*\(/
  
  # Return the strings that represent potential mass assignment problems.
  # The MASS_ASSIGNMENT regex returns, e.g., ['Post', 'new'] because of
  # the grouping methods; we want the first of the two for each match.
  # For example, the call to scan might return
  # [['Post', 'new'], ['Person', 'create']]
  # We then select the first element of each subarray, returning
  # ['Post', 'Person']
  def mass_assignment_models
    scan(MASS_ASSIGNMENT).map { |problem| problem.first.classify }
  end
 
  # Return true if the string has potential mass assignment code.
  def mass_assignment?
    self =~ MASS_ASSIGNMENT
  end
  
  # Return true if the model defines attr_accessible.
  # Note that 'attr_accessible' must be preceded by nothing other than
  # whitespace; this catches cases where attr_accessible is commented out.
  def attr_accessible?
    model = "#{RAILS_ROOT}/app/models/#{self.classify}.rb"
    if File.exist?(model)
      return @@cache[model] unless @@cache[model].nil?
      @@cache[model] = File.open(model).read =~ /^\s*attr_accessible/
    else
      # If the model file doesn't exist, ignore it by returning true.
      # This way, problem? is false and the item won't be flagged.
      true
    end
  end
  
  # Returnt true if a model does not define attr_accessible.
  def problem?
    not attr_accessible?
  end
  
  # Return true if a line has a problem model (no attr_accessible).
  def problem_model?
    mass_assignment_models.find { |model| model.problem? }
  end
  
  # Return true if a controller string has a (likely) mass assignment problem.
  # This is true if at least one of the controller's lines
  # (1) Has a likely mass assignment
  # (2) The corresponding model doesn't define attr_accessible
  def mass_assignment_problem?
    File.open(self).find { |l| l.mass_assignment? and l.problem_model? }
  end
end
 
module MassAssignment
 
  def self.print_mass_assignment_problems(controller)
    lines = File.open(controller)
    lines.each_with_index do |line, number|
      if line.mass_assignment? and line.problem_model?
        puts " #{number} #{line}"
      end
    end
  end
 
  def self.find
    controllers = Dir.glob("#{RAILS_ROOT}/app/controllers/*_controller.rb")
    controllers.each do |controller|
      if controller.mass_assignment_problem?
        puts "\n#{controller}"
        print_mass_assignment_problems(controller)
      end
    end
  end
end
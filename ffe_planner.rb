require 'sketchup.rb'
require 'extensions.rb'

module FFEPlanner
  module_function

  def self.load_extension
    extension_file = File.join(File.dirname(__FILE__), 'ffe_planner', 'main.rb')
    extension = SketchupExtension.new('FFE Planner', extension_file)
    extension.version = '1.0.0'
    extension.description = 'Manage and export Furniture, Fixtures, and Equipment (FFE) information.'
    extension.creator = 'Your Name' # Replace with your actual name or organization
    Sketchup.register_extension(extension, true)
  end
end

unless file_loaded?(__FILE__)
  FFEPlanner.load_extension
  file_loaded(__FILE__)
end

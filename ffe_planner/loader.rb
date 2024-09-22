# ffe_planner/loader.rb

module FFEPlanner
  module Loader
    # Add the plugin directory to the Ruby load path
    plugin_dir = File.dirname(__FILE__)
    $LOAD_PATH << plugin_dir unless $LOAD_PATH.include?(plugin_dir)

    # Require all necessary files
    require 'main'
    require 'ffe_product_manager'
    require 'finishes_manager'
    require 'exporter'

    # Any additional setup can be done here
    def self.start
      # Perform any necessary startup tasks
      puts "FFE Planner plugin loaded successfully"
    end
  end
end

# Start the plugin
FFEPlanner::Loader.start

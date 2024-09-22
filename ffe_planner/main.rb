require 'sketchup.rb'
require 'fileutils'
require 'json'
require 'base64'

module FFEPlanner
  module Main
    # Path to the plugin directory
    PLUGIN_DIR = File.dirname(__FILE__)

    # Path to the thumbnails directory
    THUMBNAILS_DIR = File.join(PLUGIN_DIR, 'thumbnails')

    # Initialize the plugin
    def self.initialize_plugin
      create_thumbnails_directory
      create_menus
    end

    # Create the thumbnails directory if it doesn't exist
    def self.create_thumbnails_directory
      unless Dir.exist?(THUMBNAILS_DIR)
        FileUtils.mkdir_p(THUMBNAILS_DIR)
        puts "FFE Planner: Created thumbnails directory at #{THUMBNAILS_DIR}"
      end
    end

    # Create the plugin menus in SketchUp
    def self.create_menus
      if @submenu.nil?
        @submenu = UI.menu('Plugins').add_submenu('FFE Planner')
        @submenu.add_item('Product Manager') { FFEPlanner::FFEProductManager.show_dialog }
        @submenu.add_item('Finish Manager') { FFEPlanner::FinishesManager.show_dialog }
        @submenu.add_item('Export Finishes HTML') { FFEPlanner::Exporter.export_finishes_html }
        @submenu.add_item('Export FFE HTML') { FFEPlanner::Exporter.export_ffe_html }
      end
    end

    # Handle different actions triggered from HTML dialogs
    def self.handle_action(action, params)
      case action
      when 'delete_product'
        delete_product(params)
      when 'export_as_dwg'
        export_as_dwg(params)
      when 'update_cost_per_unit'
        product_id, value = params.split('&')
        update_cost_per_unit(product_id, value.to_f)
      when 'update_ffe_type'
        product_id, value = params.split('&')
        update_ffe_type(product_id, value)
      when 'update_supplier'
        product_id, value = params.split('&')
        update_supplier(product_id, value)
      when 'update_additional_info'
        product_id, value = params.split('&')
        update_additional_info(product_id, value)
      when 'delete_material'
        delete_material(params)
      when 'tag_as_finish'
        tag_as_finish(params)
      when 'update_cost_per_sqm'
        material_id, value = params.split('&')
        update_cost_per_sqm(material_id, value.to_f)
      when 'update_material_supplier'
        material_id, value = params.split('&')
        update_material_supplier(material_id, value)
      when 'update_material_additional_info'
        material_id, value = params.split('&')
        update_material_additional_info(material_id, value)
      else
        puts "FFE Planner: Unknown action '#{action}' with params '#{params}'"
      end
    end

    # Callback Methods

    # Delete a product by its ID
    def self.delete_product(product_id)
      model = Sketchup.active_model
      component = model.definitions.find { |d| d.get_attribute('FFEPlanner', 'id') == product_id }
      if component
        component.instances.each(&:erase!)
        model.definitions.erase(component)
        UI.messagebox("Product '#{product_id}' deleted successfully.")
      else
        UI.messagebox("Product '#{product_id}' not found.")
      end
    end

    # Export a product as DWG
    def self.export_as_dwg(product_id)
      model = Sketchup.active_model
      component = model.definitions.find { |d| d.get_attribute('FFEPlanner', 'id') == product_id }
      unless component
        UI.messagebox("Product '#{product_id}' not found.")
        return
      end

      # Ask user where to save the DWG file
      save_path = UI.savepanel("Export as DWG", "", "#{product_id}.dwg")
      unless save_path
        UI.messagebox("Export cancelled.")
        return
      end

      # Create a temporary group and insert the component
      model.start_operation('Export as DWG', true)
      begin
        group = model.entities.add_group
        group.entities.add_instance(component, Geom::Transformation.new)

        # Zoom to fit the group
        view = model.active_view
        view.zoom_extents

        # Export the model as DWG
        model.export(save_path, { :formats => 'dwg' })
        UI.messagebox("Product '#{product_id}' exported as DWG successfully to:\n#{save_path}")
      rescue => e
        UI.messagebox("Failed to export DWG: #{e.message}")
      ensure
        # Erase the temporary group
        model.entities.erase_entities(group) if group && group.valid?
        model.commit_operation
      end
    end

    # Update the cost per unit for a product
    def self.update_cost_per_unit(product_id, value)
      component = Sketchup.active_model.definitions.find { |d| d.get_attribute('FFEPlanner', 'id') == product_id }
      if component
        component.set_attribute('FFEPlanner', 'cost_per_unit', value)
        UI.messagebox("Cost per unit for '#{product_id}' updated to #{value}.")
      else
        UI.messagebox("Product '#{product_id}' not found.")
      end
    end

    # Update the FFE type for a product
    def self.update_ffe_type(product_id, value)
      component = Sketchup.active_model.definitions.find { |d| d.get_attribute('FFEPlanner', 'id') == product_id }
      if component
        component.set_attribute('FFEPlanner', 'ffe_type', value)
        UI.messagebox("FFE Type for '#{product_id}' updated to '#{value}'.")
      else
        UI.messagebox("Product '#{product_id}' not found.")
      end
    end

    # Update the supplier for a product
    def self.update_supplier(product_id, value)
      component = Sketchup.active_model.definitions.find { |d| d.get_attribute('FFEPlanner', 'id') == product_id }
      if component
        component.set_attribute('FFEPlanner', 'supplier', value)
        UI.messagebox("Supplier for '#{product_id}' updated to '#{value}'.")
      else
        UI.messagebox("Product '#{product_id}' not found.")
      end
    end

    # Update the additional info for a product
    def self.update_additional_info(product_id, value)
      component = Sketchup.active_model.definitions.find { |d| d.get_attribute('FFEPlanner', 'id') == product_id }
      if component
        component.set_attribute('FFEPlanner', 'additional_info', value)
        UI.messagebox("Additional Info for '#{product_id}' updated.")
      else
        UI.messagebox("Product '#{product_id}' not found.")
      end
    end

    # Delete a material by its ID
    def self.delete_material(material_id)
      model = Sketchup.active_model
      material = model.materials.find { |m| m.get_attribute('FFEPlanner', 'id') == material_id }
      if material
        model.materials.erase(material)
        UI.messagebox("Material '#{material_id}' deleted successfully.")
      else
        UI.messagebox("Material '#{material_id}' not found.")
      end
    end

    # Tag a material as Finish
    def self.tag_as_finish(material_id)
      model = Sketchup.active_model
      material = model.materials.find { |m| m.get_attribute('FFEPlanner', 'id') == material_id }
      if material
        material.set_attribute('FFEPlanner', 'is_finish', true)
        UI.messagebox("Material '#{material_id}' tagged as Finish.")
      else
        UI.messagebox("Material '#{material_id}' not found.")
      end
    end

    # Update the cost per sqm for a material
    def self.update_cost_per_sqm(material_id, value)
      material = Sketchup.active_model.materials.find { |m| m.get_attribute('FFEPlanner', 'id') == material_id }
      if material
        material.set_attribute('FFEPlanner', 'cost_per_sqm', value)
        UI.messagebox("Cost per sqm for '#{material_id}' updated to #{value}.")
      else
        UI.messagebox("Material '#{material_id}' not found.")
      end
    end

    # Update the supplier for a material
    def self.update_material_supplier(material_id, value)
      material = Sketchup.active_model.materials.find { |m| m.get_attribute('FFEPlanner', 'id') == material_id }
      if material
        material.set_attribute('FFEPlanner', 'supplier', value)
        UI.messagebox("Supplier for '#{material_id}' updated to '#{value}'.")
      else
        UI.messagebox("Material '#{material_id}' not found.")
      end
    end

    # Update the additional info for a material
    def self.update_material_additional_info(material_id, value)
      material = Sketchup.active_model.materials.find { |m| m.get_attribute('FFEPlanner', 'id') == material_id }
      if material
        material.set_attribute('FFEPlanner', 'additional_info', value)
        UI.messagebox("Additional Info for '#{material_id}' updated.")
      else
        UI.messagebox("Material '#{material_id}' not found.")
      end
    end

    # Save user preferences
    def self.save_preferences(preferences)
      model = Sketchup.active_model
      model.set_attribute('FFEPlanner', 'preferences', preferences)
      UI.messagebox("Preferences saved successfully.")
    end

    # Load user preferences
    def self.load_preferences
      model = Sketchup.active_model
      preferences = model.get_attribute('FFEPlanner', 'preferences', {})
      preferences
    end

    # Generate a thumbnail for a component
    def self.generate_component_thumbnail(component)
      return "placeholder.png" unless component

      # Define the thumbnail file path
      thumbnail_filename = "#{component.name.gsub(/[^0-9A-Za-z.\-]/, '_')}.png"
      thumbnail_path = File.join(THUMBNAILS_DIR, thumbnail_filename)

      # Return existing thumbnail if it exists
      if File.exist?(thumbnail_path)
        return "file:///#{thumbnail_path.gsub(' ', '%20')}"
      end

      model = Sketchup.active_model
      view = model.active_view

      model.start_operation('Generate Component Thumbnail', true)
      begin
        # Create a temporary group and insert the component
        group = model.entities.add_group
        group.entities.add_instance(component, Geom::Transformation.new)

        # Zoom to fit the group
        view.zoom_extents

        # Set image options
        options = {
          :filename => thumbnail_path,
          :width => 200,
          :height => 200,
          :antialias => true,
          :transparent => false,
          :compression => 90
        }

        # Capture the view as image
        view.write_image(options)
        puts "FFE Planner: Generated thumbnail for component '#{component.name}' at #{thumbnail_path}"
      rescue => e
        UI.messagebox("Failed to generate thumbnail for component '#{component.name}': #{e.message}")
        thumbnail_path = "placeholder.png"
      ensure
        # Erase the temporary group
        model.entities.erase_entities(group) if group && group.valid?
        model.commit_operation
      end

      # Return the file URL
      "file:///#{thumbnail_path.gsub(' ', '%20')}"
    end

    # Generate a thumbnail for a material using its texture
    def self.generate_material_thumbnail(material)
      return "placeholder.png" unless material && material.texture

      # Define the thumbnail file path
      thumbnail_filename = "#{material.name.gsub(/[^0-9A-Za-z.\-]/, '_')}.png"
      thumbnail_path = File.join(THUMBNAILS_DIR, thumbnail_filename)

      # Return existing thumbnail if it exists
      if File.exist?(thumbnail_path)
        return "file:///#{thumbnail_path.gsub(' ', '%20')}"
      end

      model = Sketchup.active_model
      view = model.active_view

      model.start_operation('Generate Material Thumbnail', true)
      begin
        # Create a temporary group and add a face with the material
        group = model.entities.add_group
        width = 100
        height = 100
        pts = [
          Geom::Point3d.new(0, 0, 0),
          Geom::Point3d.new(width, 0, 0),
          Geom::Point3d.new(width, height, 0),
          Geom::Point3d.new(0, height, 0)
        ]
        face = group.entities.add_face(pts)
        face.material = material
        face.back_material = material

        # Apply a simple transformation to standardize the view
        transformation = Geom::Transformation.new([0,0,0], [1,0,0], [0,1,0], [0,0,1])
        face.transform!(transformation)

        # Zoom to fit the group
        view.zoom_extents

        # Set image options
        options = {
          :filename => thumbnail_path,
          :width => 200,
          :height => 200,
          :antialias => true,
          :transparent => false,
          :compression => 90
        }

        # Capture the view as image
        view.write_image(options)
        puts "FFE Planner: Generated thumbnail for material '#{material.name}' at #{thumbnail_path}"
      rescue => e
        UI.messagebox("Failed to generate thumbnail for material '#{material.name}': #{e.message}")
        thumbnail_path = "placeholder.png"
      ensure
        # Erase the temporary group
        model.entities.erase_entities(group) if group && group.valid?
        model.commit_operation
      end

      # Return the file URL
      "file:///#{thumbnail_path.gsub(' ', '%20')}"
    end

    # Register the plugin upon loading
    initialize_plugin
  end
end

# Require all Ruby files in the plugin directory except main.rb and ffe_planner.rb
Dir.glob(File.join(File.dirname(__FILE__), '*.rb')).each do |file|
  require file unless ['main.rb', 'ffe_planner.rb'].include?(File.basename(file))
end

unless file_loaded?(__FILE__)
  file_loaded(__FILE__)
end

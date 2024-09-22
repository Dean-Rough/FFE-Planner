module FFEPlanner
  module Exporter

    def self.export_finishes_html
      model = Sketchup.active_model
      materials = model.materials.select { |m| m.get_attribute('FFEPlanner', 'is_finish') }
      material_data = materials.map do |material|
        {
          id: material.get_attribute('FFEPlanner', 'id') || material.name,
          description: material.get_attribute('FFEPlanner', 'description') || material.display_name,
          area: calculate_material_area(material).round(2),
          cost_per_sqm: material.get_attribute('FFEPlanner', 'cost_per_sqm') || 0.0,
          total_cost: (material.get_attribute('FFEPlanner', 'cost_per_sqm') || 0.0) * calculate_material_area(material).round(2),
          supplier: material.get_attribute('FFEPlanner', 'supplier') || "",
          link: material.get_attribute('FFEPlanner', 'link') || "",
          additional_info: material.get_attribute('FFEPlanner', 'additional_info') || "",
          thumbnail: FFEPlanner::Main.generate_material_thumbnail(material)
        }
      end
      material_data.sort_by { |m| -m[:area] }

      html_content = <<-HTML
      <html>
      <head>
        <title>Finishes Export</title>
        <style>
          body { font-family: Arial, sans-serif; padding: 20px; }
          table { width: 100%; border-collapse: collapse; }
          th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
          th { background-color: #f2f2f2; }
          img { width: 50px; height: 50px; }
        </style>
      </head>
      <body>
        <h2>Finishes Export</h2>
        <table>
          <thead>
            <tr>
              <th>Thumbnail</th>
              <th>ID</th>
              <th>Description</th>
              <th>Area (sqm)</th>
              <th>Cost per sqm (£)</th>
              <th>Total Cost (£)</th>
              <th>Supplier</th>
              <th>Link</th>
              <th>Additional Info</th>
            </tr>
          </thead>
          <tbody>
            #{material_data.map { |m| export_material_row(m) }.join("\n")}
          </tbody>
        </table>
      </body>
      </html>
      HTML

      # Prompt user to save the HTML file
      save_path = UI.savepanel("Export Finishes as HTML", "", "finishes_export.html")
      return unless save_path

      File.open(save_path, 'w') { |file| file.write(html_content) }
      UI.messagebox("Finishes exported successfully to:\n#{save_path}")
    end

    def self.export_ffe_html
      model = Sketchup.active_model
      components = model.definitions.select { |d| d.get_attribute('FFEPlanner', 'is_ffe') }
      products = components.map do |component|
        {
          id: component.get_attribute('FFEPlanner', 'id') || component.name,
          name: component.get_attribute('FFEPlanner', 'name') || component.name,
          quantity: component.instances.length,
          thumbnail: FFEPlanner::Main.generate_component_thumbnail(component),
          cost_per_unit: component.get_attribute('FFEPlanner', 'cost_per_unit') || 0.0,
          total_cost: (component.get_attribute('FFEPlanner', 'cost_per_unit') || 0.0) * component.instances.length,
          ffe_type: component.get_attribute('FFEPlanner', 'ffe_type') || "Undefined",
          supplier: component.get_attribute('FFEPlanner', 'supplier') || "",
          link: component.get_attribute('FFEPlanner', 'link') || "",
          additional_info: component.get_attribute('FFEPlanner', 'additional_info') || ""
        }
      end
      products.sort_by { |p| -p[:quantity] }

      html_content = <<-HTML
      <html>
      <head>
        <title>FFE Export</title>
        <style>
          body { font-family: Arial, sans-serif; padding: 20px; }
          table { width: 100%; border-collapse: collapse; }
          th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
          th { background-color: #f2f2f2; }
          img { width: 50px; height: 50px; }
        </style>
      </head>
      <body>
        <h2>FFE Export</h2>
        <table>
          <thead>
            <tr>
              <th>Thumbnail</th>
              <th>ID</th>
              <th>Name</th>
              <th>Quantity</th>
              <th>Cost per Unit (£)</th>
              <th>Total Cost (£)</th>
              <th>FFE Type</th>
              <th>Supplier</th>
              <th>Link</th>
              <th>Additional Info</th>
            </tr>
          </thead>
          <tbody>
            #{products.map { |p| export_product_row(p) }.join("\n")}
          </tbody>
        </table>
      </body>
      </html>
      HTML

      # Prompt user to save the HTML file
      save_path = UI.savepanel("Export FFE as HTML", "", "ffe_export.html")
      return unless save_path

      File.open(save_path, 'w') { |file| file.write(html_content) }
      UI.messagebox("FFE exported successfully to:\n#{save_path}")
    end

    def self.export_material_row(material)
      <<-ROW
      <tr>
        <td><img src="#{material[:thumbnail]}" alt="Thumbnail"></td>
        <td>#{material[:id]}</td>
        <td>#{material[:description]}</td>
        <td>#{material[:area]}</td>
        <td>#{'%.2f' % material[:cost_per_sqm]}</td>
        <td>#{'%.2f' % material[:total_cost]}</td>
        <td>#{material[:supplier]}</td>
        <td><a href="#{material[:link]}" target="_blank">Link</a></td>
        <td>#{material[:additional_info]}</td>
      </tr>
      ROW
    end

    def self.export_product_row(product)
      <<-ROW
      <tr>
        <td><img src="#{product[:thumbnail]}" alt="Thumbnail"></td>
        <td>#{product[:id]}</td>
        <td>#{product[:name]}</td>
        <td>#{product[:quantity]}</td>
        <td>#{'%.2f' % product[:cost_per_unit]}</td>
        <td>#{'%.2f' % product[:total_cost]}</td>
        <td>#{product[:ffe_type]}</td>
        <td>#{product[:supplier]}</td>
        <td><a href="#{product[:link]}" target="_blank">Link</a></td>
        <td>#{product[:additional_info]}</td>
      </tr>
      ROW
    end

    def self.calculate_material_area(material)
      total_area = 0.0
      Sketchup.active_model.entities.grep(Sketchup::Face).each do |face|
        total_area += face.area if face.material == material
      end
      total_area.to_f / 929.03 # Convert square inches to square meters
    end
  end
end

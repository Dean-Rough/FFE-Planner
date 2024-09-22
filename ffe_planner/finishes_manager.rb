module FFEPlanner
  module FinishesManager
    require 'json'

    def self.show_dialog
      puts "Finishes Manager: Showing dialog"
      materials = get_finishes
      html = generate_html(materials)

      dlg = UI::HtmlDialog.new(
        {
          :dialog_title => "Finishes Manager",
          :preferences_key => "FFEPlanner_FinishesManager",
          :scrollable => true,
          :resizable => true,
          :width => 1200,
          :height => 800,
          :style => UI::HtmlDialog::STYLE_DIALOG
        }
      )

      dlg.set_html(html)

      dlg.add_action_callback("delete_material") do |_, material_id|
        FFEPlanner::Main.handle_action("delete_material", material_id)
        { status: 'success', message: "Material '#{material_id}' deleted." }.to_json
      end

      dlg.add_action_callback("tag_as_finish") do |_, material_id|
        FFEPlanner::Main.handle_action("tag_as_finish", material_id)
        { status: 'success', message: "Material '#{material_id}' tagged as Finish." }.to_json
      end

      dlg.add_action_callback("update_cost_per_sqm") do |_, params|
        FFEPlanner::Main.handle_action("update_cost_per_sqm", params)
        { status: 'success', message: "Cost per sqm updated." }.to_json
      end

      dlg.add_action_callback("update_supplier") do |_, params|
        FFEPlanner::Main.handle_action("update_material_supplier", params)
        { status: 'success', message: "Supplier updated." }.to_json
      end

      dlg.add_action_callback("update_additional_info") do |_, params|
        FFEPlanner::Main.handle_action("update_material_additional_info", params)
        { status: 'success', message: "Additional info updated." }.to_json
      end

      dlg.add_action_callback("setActiveMaterial") do |_, material_name|
        material = Sketchup.active_model.materials[material_name]
        if material
          Sketchup.active_model.materials.current = material
          UI.messagebox("Material '#{material_name}' is now active.")
        else
          UI.messagebox("Material '#{material_name}' not found.")
        end
      end

      dlg.show
    end

    def self.get_finishes
      puts "Finishes Manager: Getting materials"
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
    end

    def self.calculate_material_area(material)
      total_area = 0.0
      Sketchup.active_model.entities.grep(Sketchup::Face).each do |face|
        total_area += face.area if face.material == material
      end
      total_area.to_f / 929.03 # Convert square inches to square meters
    end

    def self.tag_as_finish(material)
      if material
        material.set_attribute('FFEPlanner', 'is_finish', true)
        UI.messagebox("#{material.name} has been tagged as Finish.")
      else
        UI.messagebox("Unable to tag material as Finish.")
      end
    end

    def self.generate_html(materials)
      rows = materials.map { |m| material_row(m) }.join("\n")
      <<-HTML
      <html>
      <head>
        <style>
          body {
            font-family: Arial, sans-serif;
            padding: 20px;
          }
          table {
            width: 100%;
            border-collapse: collapse;
          }
          th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
          }
          th {
            background-color: #f2f2f2;
          }
          .action-button {
            margin-right: 5px;
          }
          img {
            width: 50px;
            height: 50px;
          }
          input[type="number"], input[type="text"], select {
            width: 100%;
            box-sizing: border-box;
          }
        </style>
      </head>
      <body>
        <h2>Finishes Manager</h2>
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
              <th>Product URL</th>
              <th>Additional Info</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            #{rows}
          </tbody>
        </table>
        <script>
          function deleteMaterial(id) {
            if (confirm('Are you sure you want to delete material ' + id + '?')) {
              window.sketchup.delete_material(id);
            }
          }

          function tagAsFinish(id) {
            window.sketchup.tag_as_finish(id);
          }

          function updateCostPerSqm(id, value) {
            window.sketchup.update_cost_per_sqm(id + '&' + value);
          }

          function updateSupplier(id, value) {
            window.sketchup.update_supplier(id + '&' + value);
          }

          function updateAdditionalInfo(id, value) {
            window.sketchup.update_additional_info(id + '&' + value);
          }

          function setActiveMaterial(id) {
            window.sketchup.setActiveMaterial(id);
          }
        </script>
      </body>
      </html>
      HTML
    end

    def self.material_row(material)
      <<-ROW
      <tr>
        <td><img src="#{material[:thumbnail]}" alt="Thumbnail"></td>
        <td>#{material[:id]}</td>
        <td><input type="text" value="#{material[:description]}" onchange="updateCostPerSqm('#{material[:id]}', this.value)"></td>
        <td>#{material[:area]}</td>
        <td><input type="number" value="#{material[:cost_per_sqm]}" onchange="updateCostPerSqm('#{material[:id]}', this.value)"></td>
        <td>#{'%.2f' % material[:total_cost]}</td>
        <td><input type="text" value="#{material[:supplier]}" onchange="updateSupplier('#{material[:id]}', this.value)"></td>
        <td><input type="text" value="#{material[:link]}" onchange="updateLink('#{material[:id]}', this.value)"></td>
        <td><input type="text" value="#{material[:additional_info]}" onchange="updateAdditionalInfo('#{material[:id]}', this.value)"></td>
        <td>
          <button class="action-button" onclick="tagAsFinish('#{material[:id]}')">Tag as Finish</button>
          <button class="action-button" onclick="deleteMaterial('#{material[:id]}')">Delete</button>
          <button class="action-button" onclick="setActiveMaterial('#{material[:id]}')">Paintbrush</button>
        </td>
      </tr>
      ROW
    end
  end
end

# Add menu item to launch the dialog
unless file_loaded?(__FILE__)
  menu = UI.menu('Plugins')
  menu.add_item('Finishes Manager') {
    FFEPlanner::FinishesManager.show_dialog
  }
  file_loaded(__FILE__)
end

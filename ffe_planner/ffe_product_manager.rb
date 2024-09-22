module FFEPlanner
  module FFEProductManager
    require 'json'

    def self.show_dialog
      puts "FFE Product Manager: Showing dialog"
      products = get_ffe_products
      html = generate_html(products)

      dlg = UI::HtmlDialog.new(
        {
          :dialog_title => "FFE Product Manager",
          :preferences_key => "FFEPlanner_FFEProductManager",
          :scrollable => true,
          :resizable => true,
          :width => 1200,
          :height => 800,
          :style => UI::HtmlDialog::STYLE_DIALOG
        }
      )

      dlg.set_html(html)

      dlg.add_action_callback("delete_product") do |_, product_id|
        FFEPlanner::Main.handle_action("delete_product", product_id)
        { status: 'success', message: "Product '#{product_id}' deleted." }.to_json
      end

      dlg.add_action_callback("export_as_dwg") do |_, product_id|
        FFEPlanner::Main.handle_action("export_as_dwg", product_id)
        { status: 'success', message: "Export initiated for '#{product_id}'." }.to_json
      end

      dlg.add_action_callback("update_cost_per_unit") do |_, params|
        FFEPlanner::Main.handle_action("update_cost_per_unit", params)
        { status: 'success', message: "Cost per unit updated." }.to_json
      end

      dlg.add_action_callback("update_ffe_type") do |_, params|
        FFEPlanner::Main.handle_action("update_ffe_type", params)
        { status: 'success', message: "FFE type updated." }.to_json
      end

      dlg.add_action_callback("update_supplier") do |_, params|
        FFEPlanner::Main.handle_action("update_supplier", params)
        { status: 'success', message: "Supplier updated." }.to_json
      end

      dlg.add_action_callback("update_link") do |_, params|
        FFEPlanner::Main.handle_action("update_link", params)
        { status: 'success', message: "Product URL updated." }.to_json
      end

      dlg.add_action_callback("update_name") do |_, params|
        FFEPlanner::Main.handle_action("update_name", params)
        { status: 'success', message: "Product name updated." }.to_json
      end

      dlg.add_action_callback("update_additional_info") do |_, params|
        FFEPlanner::Main.handle_action("update_additional_info", params)
        { status: 'success', message: "Additional info updated." }.to_json
      end

      dlg.add_action_callback("untag_as_ffe") do |_, product_id|
        untag_as_ffe(product_id)
        { status: 'success', message: "Product '#{product_id}' untagged as FFE." }.to_json
      end

      dlg.show
    end

    def self.get_ffe_products
      puts "FFE Product Manager: Getting FFE products"
      model = Sketchup.active_model
      components = model.definitions.select { |d| is_ffe?(d) }
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
      products
    end

    def self.is_ffe?(component)
      is_ffe = component.attribute_dictionary('FFEPlanner') &&
               component.get_attribute('FFEPlanner', 'is_ffe')
      puts "FFE Product Manager: Checking component #{component.name}: is_ffe = #{is_ffe}"
      is_ffe
    end

    def self.tag_as_ffe(entity)
      if entity.respond_to?(:definition)
        entity.definition.set_attribute('FFEPlanner', 'is_ffe', true)
        UI.messagebox("#{entity.definition.name} has been tagged as FFE.")
      else
        UI.messagebox("Unable to tag entity as FFE.")
      end
    end

    def self.untag_as_ffe(product_id)
      component = Sketchup.active_model.definitions.find { |d| d.get_attribute('FFEPlanner', 'id') == product_id }
      if component
        component.delete_attribute('FFEPlanner', 'is_ffe')
        UI.messagebox("Product '#{product_id}' has been untagged as FFE.")
      else
        UI.messagebox("Product '#{product_id}' not found.")
      end
    end

    def self.generate_html(products)
      rows = products.map { |p| product_row(p) }.join("\n")
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
        <h2>FFE Product Manager</h2>
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
          function deleteProduct(id) {
            if (confirm('Are you sure you want to delete product ' + id + '?')) {
              window.sketchup.delete_product(id);
            }
          }

          function exportAsDWG(id) {
            window.sketchup.export_as_dwg(id);
          }

          function updateCostPerUnit(id, value) {
            window.sketchup.update_cost_per_unit(id + '&' + value);
          }

          function updateFFEType(id, value) {
            window.sketchup.update_ffe_type(id + '&' + value);
          }

          function updateSupplier(id, value) {
            window.sketchup.update_supplier(id + '&' + value);
          }

          function updateLink(id, value) {
            window.sketchup.update_link(id + '&' + value);
          }

          function updateName(id, value) {
            window.sketchup.update_name(id + '&' + value);
          }

          function updateAdditionalInfo(id, value) {
            window.sketchup.update_additional_info(id + '&' + value);
          }

          function untagAsFFE(id) {
            window.sketchup.untag_as_ffe(id);
          }
        </script>
      </body>
      </html>
      HTML
    end

    def self.product_row(product)
      <<-ROW
      <tr>
        <td><img src="#{product[:thumbnail]}" alt="Thumbnail"></td>
        <td><input type="text" value="#{product[:id]}" onchange="updateName('#{product[:id]}', this.value)"></td>
        <td><input type="text" value="#{product[:name]}" onchange="updateName('#{product[:id]}', this.value)"></td>
        <td>#{product[:quantity]}</td>
        <td><input type="number" value="#{product[:cost_per_unit]}" onchange="updateCostPerUnit('#{product[:id]}', this.value)"></td>
        <td>#{'%.2f' % product[:total_cost]}</td>
        <td>
          <select onchange="updateFFEType('#{product[:id]}', this.value)">
            <option value="Furniture" #{'selected' if product[:ffe_type] == 'Furniture'}>Furniture</option>
            <option value="Lighting" #{'selected' if product[:ffe_type] == 'Lighting'}>Lighting</option>
            <option value="AV" #{'selected' if product[:ffe_type] == 'AV'}>AV</option>
            <option value="Utilities" #{'selected' if product[:ffe_type] == 'Utilities'}>Utilities</option>
            <option value="Custom" #{'selected' if product[:ffe_type] == 'Custom'}>Custom</option>
          </select>
        </td>
        <td><input type="text" value="#{product[:supplier]}" onchange="updateSupplier('#{product[:id]}', this.value)"></td>
        <td><input type="text" value="#{product[:link]}" onchange="updateLink('#{product[:id]}', this.value)"></td>
        <td><input type="text" value="#{product[:additional_info]}" onchange="updateAdditionalInfo('#{product[:id]}', this.value)"></td>
        <td>
          <button class="action-button" onclick="untagAsFFE('#{product[:id]}')">Untag as FFE</button>
          <button class="action-button" onclick="exportAsDWG('#{product[:id]}')">Export as DWG</button>
        </td>
      </tr>
      ROW
    end
  end
end

# Add menu item to launch the dialog
unless file_loaded?(__FILE__)
  menu = UI.menu('Plugins')
  menu.add_item('FFE Product Manager') {
    FFEPlanner::FFEProductManager.show_dialog
  }
  file_loaded(__FILE__)
end

defmodule EnterpriseShopWeb.WarehouseLiveTest do
  use EnterpriseShopWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  describe "Warehouse Dashboard LiveView" do
    setup do
      enterprise = insert(:enterprise)
      warehouse = insert(:warehouse, name: "Test Warehouse", enterprise: enterprise)
      store = insert(:store, name: "Test Store", enterprise: enterprise)

      product_pointer = insert(:product, name: "Super Laser Pointer", sku: "LASER-001")
      product_boots = insert(:product, name: "Anti-Gravity Boots", sku: "BOOTS-002")

      insert(:inventory_item,
        product: product_pointer,
        location_type: "warehouse",
        location_id: warehouse.id,
        quantity: 50
      )

      insert(:inventory_item,
        product: product_boots,
        location_type: "store",
        location_id: store.id,
        quantity: 15
      )

      %{
        warehouse: warehouse,
        store: store,
        product_pointer: product_pointer,
        product_boots: product_boots
      }
    end

    test "renders dashboard with warehouse and store items including inline thumbnails", %{
      conn: conn,
      warehouse: warehouse,
      store: store,
      product_pointer: product_pointer,
      product_boots: product_boots
    } do
      {:ok, view, html} = live(conn, ~p"/warehouse/dashboard")

      # Verify dashboard header and elements exist
      assert html =~ "Enterprise Dashboard"
      assert html =~ warehouse.name
      assert html =~ store.name
      assert html =~ product_pointer.name
      assert html =~ product_boots.name

      # Verify inline thumbnail images are rendered in rows
      assert has_element?(
               view,
               "tr#wh-item-#{warehouse.id}-#{product_pointer.id} img[src*='pointer.png']"
             )

      assert has_element?(
               view,
               "tr#store-item-#{store.id}-#{product_boots.id} img[src*='boots.png']"
             )
    end

    test "can highlight specific product type when clicking thumbnail buttons", %{
      conn: conn,
      store: store,
      product_boots: product_boots
    } do
      {:ok, view, _html} = live(conn, ~p"/warehouse/dashboard")

      # Initially no rows should be highlighted with table-warning
      refute has_element?(view, "tr.table-warning")

      # Click to highlight Anti-Gravity Boots (ID/product_boots.id)
      view
      |> element("#highlight-btn-boots")
      |> render_click()

      # The boots row in the store table should be highlighted
      assert has_element?(view, "tr#store-item-#{store.id}-#{product_boots.id}.table-warning")

      # Click to clear highlight or toggle the same product off
      view
      |> element("#highlight-btn-boots")
      |> render_click()

      # Highlight should be gone
      refute has_element?(view, "tr.table-warning")
    end
  end
end

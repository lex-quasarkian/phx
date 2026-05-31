defmodule EnterpriseShopWeb.StoreLiveTest do
  use EnterpriseShopWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  describe "Storefront LiveView" do
    setup do
      enterprise = insert(:enterprise)
      store = insert(:store, name: "Super Test Store", enterprise: enterprise)
      product = insert(:product, name: "Laser Saber", price: Decimal.new("120.00"))

      insert(:inventory_item,
        product: product,
        location_type: "store",
        location_id: store.id,
        quantity: 5
      )

      %{store: store, product: product}
    end

    test "renders storefront with store name and product list", %{
      conn: conn,
      store: store,
      product: product
    } do
      {:ok, _view, html} = live(conn, ~p"/store")

      # Verify page contains title elements
      assert html =~ "Storefront Catalog"
      assert html =~ store.name
      assert html =~ product.name
    end

    test "can add item to cart and see updated cart badge", %{conn: conn, product: product} do
      {:ok, view, _html} = live(conn, ~p"/store")

      # Select add to cart button element and click it
      button_selector = "#add-to-cart-btn-#{product.id}"
      assert has_element?(view, button_selector)

      # Click button
      view
      |> element(button_selector)
      |> render_click()

      # Assert flash message is shown
      assert render(view) =~ "Added item to cart"
    end
  end
end

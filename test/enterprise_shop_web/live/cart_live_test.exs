defmodule EnterpriseShopWeb.CartLiveTest do
  use EnterpriseShopWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Mox

  alias EnterpriseShop.Sales.CartRegistry
  alias EnterpriseShop.Domain.Cart

  setup :verify_on_exit!

  describe "Shopping Cart LiveView" do
    setup do
      enterprise = insert(:enterprise)
      store = insert(:store, name: "Super Test Store", enterprise: enterprise)
      product = insert(:product, name: "Laser Saber", price: Decimal.new("120.00"))

      insert(:inventory_item,
        product: product,
        location_type: "store",
        location_id: store.id,
        quantity: 10
      )

      # Warehouse starts with stock in case restock is triggered
      insert(:inventory_item,
        product: product,
        location_type: "warehouse",
        # default warehouse id
        location_id: 1,
        quantity: 100
      )

      %{store: store, product: product}
    end

    test "renders empty state when cart has no items", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/cart")
      assert html =~ "Your cart is empty"
    end

    test "can place order when cart contains items", %{
      conn: conn,
      product: product
    } do
      # 1. Access connection session to seed cart
      # Initialize test session first, then fetch storefront to trigger plug
      conn = conn |> init_test_session(%{}) |> get(~p"/store")
      session_id = get_session(conn, :session_id)

      # Seed cart registry directly
      CartRegistry.update_cart(session_id, fn cart ->
        Cart.add_item(cart, product.id, 2)
      end)

      # Load Cart page
      {:ok, view, _html} = live(conn, ~p"/cart")

      # Assert product details are displayed
      assert has_element?(view, "#cart-item-#{product.id}")
      assert render(view) =~ product.name

      # Place order triggers Checkout which redirects to /store on success
      # Since stock (10 - 2 = 8) is above threshold of 5, no HTTP client post is hit.
      view
      |> element("#place-order")
      |> render_click()

      # Assert redirection back to Store
      assert_redirected(view, "/store")
    end
  end
end

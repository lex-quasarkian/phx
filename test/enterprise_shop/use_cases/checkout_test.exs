defmodule EnterpriseShop.UseCases.CheckoutTest do
  use EnterpriseShop.DataCase, async: false
  import Mox

  alias EnterpriseShop.UseCases.Checkout
  alias EnterpriseShop.Inventory
  alias EnterpriseShop.Sales
  alias EnterpriseShop.Schemas.InventoryItem

  setup :verify_on_exit!

  describe "execute/2 (Checkout Use Case)" do
    setup do
      # Set up Enterprise, Store, Warehouse, and Product
      enterprise = insert(:enterprise)
      warehouse = insert(:warehouse, enterprise: enterprise)
      store = insert(:store, enterprise: enterprise, restock_threshold: 5)
      product = insert(:product, price: Decimal.new("15.00"))

      # Store starts with 10 units
      store_item =
        insert(:inventory_item,
          product: product,
          location_type: "store",
          location_id: store.id,
          quantity: 10
        )

      # Warehouse starts with 100 units
      warehouse_item =
        insert(:inventory_item,
          product: product,
          location_type: "warehouse",
          location_id: warehouse.id,
          quantity: 100
        )

      %{
        store: store,
        warehouse: warehouse,
        product: product,
        store_item: store_item,
        warehouse_item: warehouse_item
      }
    end

    test "successful checkout with sufficient stock above threshold", %{
      store: store,
      product: product
    } do
      # Buying 2 units (10 -> 8, which is above threshold of 5)
      # No HTTP request mock should be hit because stock doesn't fall below 5.
      Mox.stub(EnterpriseShop.HTTPClientMock, :post, fn _url, _body ->
        flunk("Should not trigger restocking when stock is above threshold")
      end)

      assert {:ok, order} = Checkout.execute(store.id, %{product.id => 2})
      assert order.state == "registered"
      assert order.total_price == Decimal.new("30.00")

      # Assert stock decreased
      updated_store_item = Inventory.get_inventory_item("store", store.id, product.id)
      assert updated_store_item.quantity == 8
    end

    test "successful checkout with stock falling below threshold triggers restocking", %{
      store: store,
      product: product
    } do
      # Buying 6 units (10 -> 4, which is below threshold of 5)
      # This should trigger restocking asynchronously.
      test_pid = self()

      Mox.expect(EnterpriseShop.HTTPClientMock, :post, 1, fn url, body ->
        assert String.contains?(url, "/api/v1/warehouse/restock")
        assert body["store_id"] == store.id
        assert body["product_id"] == product.id
        send(test_pid, :restock_triggered)
        {:ok, %{status: 200}}
      end)

      assert {:ok, order} = Checkout.execute(store.id, %{product.id => 6})
      assert order.state == "registered"

      # Assert stock decreased
      updated_store_item = Inventory.get_inventory_item("store", store.id, product.id)
      assert updated_store_item.quantity == 4

      # Wait for async task to execute
      assert_receive :restock_triggered, 1000
    end

    test "failed checkout due to insufficient stock rolls back changes and triggers restocking",
         %{
           store: store,
           product: product
         } do
      # Buying 15 units (only 10 available)
      test_pid = self()

      Mox.expect(EnterpriseShop.HTTPClientMock, :post, 1, fn _url, body ->
        assert body["store_id"] == store.id
        assert body["product_id"] == product.id
        send(test_pid, :restock_triggered)
        {:ok, %{status: 200}}
      end)

      assert {:error, {:insufficient_stock, product_id}} =
               Checkout.execute(store.id, %{product.id => 15})

      assert product_id == product.id

      # Assert stock remains at 10 (rolled back)
      updated_store_item = Inventory.get_inventory_item("store", store.id, product.id)
      assert updated_store_item.quantity == 10

      # Wait for async task to execute
      assert_receive :restock_triggered, 1000
    end
  end
end

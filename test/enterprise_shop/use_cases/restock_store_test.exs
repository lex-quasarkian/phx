defmodule EnterpriseShop.UseCases.RestockStoreTest do
  use EnterpriseShop.DataCase, async: false

  alias EnterpriseShop.UseCases.RestockStore
  alias EnterpriseShop.Inventory
  alias EnterpriseShop.Schemas.InventoryItem

  describe "RestockStore use case and GenServer integration" do
    setup do
      enterprise = insert(:enterprise)
      warehouse = insert(:warehouse, enterprise: enterprise)
      store = insert(:store, enterprise: enterprise)
      product = insert(:product)

      # Store starts with 2 units
      store_item =
        insert(:inventory_item,
          product: product,
          location_type: "store",
          location_id: store.id,
          quantity: 2
        )

      # Warehouse starts with 25 units
      warehouse_item =
        insert(:inventory_item,
          product: product,
          location_type: "warehouse",
          location_id: warehouse.id,
          quantity: 25
        )

      %{
        store: store,
        warehouse: warehouse,
        product: product,
        store_item: store_item,
        warehouse_item: warehouse_item
      }
    end

    test "successful restocking transfers inventory from warehouse to store", %{
      store: store,
      warehouse: warehouse,
      product: product
    } do
      # Subscribe to PubSub to verify dashboard updates
      Phoenix.PubSub.subscribe(EnterpriseShop.PubSub, "inventory_updates")

      assert {:ok, :restocked} = RestockStore.execute(warehouse.id, store.id, product.id, 10)

      # Check updated stock levels
      wh_item = Inventory.get_inventory_item("warehouse", warehouse.id, product.id)
      st_item = Inventory.get_inventory_item("store", store.id, product.id)

      # 25 - 10
      assert wh_item.quantity == 15
      # 2 + 10
      assert st_item.quantity == 12

      # Assert PubSub update broadcasted
      assert_receive {:inventory_updated,
                      %{product_id: p_id, store_id: s_id, warehouse_id: w_id}},
                     1000

      assert p_id == product.id
      assert s_id == store.id
      assert w_id == warehouse.id
    end

    test "restocking fails if warehouse has insufficient inventory", %{
      store: store,
      warehouse: warehouse,
      product: product
    } do
      assert {:error, :insufficient_warehouse_stock} =
               RestockStore.execute(warehouse.id, store.id, product.id, 50)

      # Check stock levels unchanged
      wh_item = Inventory.get_inventory_item("warehouse", warehouse.id, product.id)
      st_item = Inventory.get_inventory_item("store", store.id, product.id)

      assert wh_item.quantity == 25
      assert st_item.quantity == 2
    end
  end
end

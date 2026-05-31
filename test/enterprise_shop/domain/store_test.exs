defmodule EnterpriseShop.Domain.StoreTest do
  use ExUnit.Case, async: true
  alias EnterpriseShop.Domain.Store

  describe "Store domain functions" do
    test "needs_restock?/2 checks quantity against threshold" do
      # Default threshold is 5
      store = Store.new("store_1", "Downtown Store", %{"prod_1" => 4, "prod_2" => 6}, 5)

      assert Store.needs_restock?(store, "prod_1") == true
      assert Store.needs_restock?(store, "prod_2") == false
      # 0 < 5
      assert Store.needs_restock?(store, "non_existent") == true
    end

    test "deduct_stock/3 reduces inventory when sufficient stock exists" do
      store = Store.new("store_1", "Downtown Store", %{"prod_1" => 10})

      assert {:ok, updated} = Store.deduct_stock(store, "prod_1", 3)
      assert updated.inventory["prod_1"] == 7
    end

    test "deduct_stock/3 returns error if stock is insufficient" do
      store = Store.new("store_1", "Downtown Store", %{"prod_1" => 2})

      assert {:error, :insufficient_stock} = Store.deduct_stock(store, "prod_1", 3)
    end

    test "add_stock/3 increases store inventory" do
      store = Store.new("store_1", "Downtown Store", %{"prod_1" => 10})
      updated = Store.add_stock(store, "prod_1", 5)

      assert updated.inventory["prod_1"] == 15
    end
  end
end

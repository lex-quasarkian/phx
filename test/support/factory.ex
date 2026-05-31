defmodule EnterpriseShop.Factory do
  use ExMachina.Ecto, repo: EnterpriseShop.Repo

  def enterprise_factory do
    %EnterpriseShop.Schemas.Enterprise{
      name: "Test Enterprise"
    }
  end

  def warehouse_factory do
    %EnterpriseShop.Schemas.Warehouse{
      name: "Test Warehouse",
      enterprise: insert(:enterprise)
    }
  end

  def store_factory do
    %EnterpriseShop.Schemas.Store{
      name: "Test Store",
      enterprise: insert(:enterprise),
      restock_threshold: 5
    }
  end

  def product_factory do
    sequence(:sku, &"SKU-#{&1}")

    %EnterpriseShop.Schemas.Product{
      name: "Test Product",
      sku: string_to_uniq_sku(),
      price: Decimal.new("10.00")
    }
  end

  def inventory_item_factory do
    %EnterpriseShop.Schemas.InventoryItem{
      product: insert(:product),
      location_type: "store",
      location_id: 1,
      quantity: 10
    }
  end

  # Helper for unique SKUs
  defp string_to_uniq_sku do
    "SKU-#{System.unique_integer([:positive])}"
  end
end

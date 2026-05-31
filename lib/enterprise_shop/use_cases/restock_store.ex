defmodule EnterpriseShop.UseCases.RestockStore do
  @moduledoc """
  RestockStore Use Case. Handles restocking store inventory from warehouse.
  Runs through the serialized WarehouseServer GenServer to avoid race conditions.
  """

  alias EnterpriseShop.Inventory.WarehouseServer

  @doc """
  Executes restocking for a store from a warehouse.
  """
  def execute(warehouse_id, store_id, product_id, quantity) do
    WarehouseServer.restock(warehouse_id, store_id, product_id, quantity)
  end
end

defmodule EnterpriseShop.Inventory.WarehouseServer do
  use GenServer, restart: :transient

  alias EnterpriseShop.Inventory
  alias EnterpriseShop.Repo
  alias EnterpriseShop.Schemas.InventoryItem
  import Ecto.Query

  # Client API

  @doc """
  Starts a WarehouseServer GenServer for a specific warehouse.
  """
  def start_link(warehouse_id) do
    GenServer.start_link(__MODULE__, warehouse_id, name: via_tuple(warehouse_id))
  end

  @doc """
  Ensures the GenServer for the warehouse is running, then calls it to restock a store.
  """
  def restock(warehouse_id, store_id, product_id, quantity) do
    case DynamicSupervisor.start_child(
           EnterpriseShop.WarehouseSupervisor,
           {__MODULE__, warehouse_id}
         ) do
      {:ok, _pid} ->
        call_restock(warehouse_id, store_id, product_id, quantity)

      {:error, {:already_started, _pid}} ->
        call_restock(warehouse_id, store_id, product_id, quantity)

      other ->
        other
    end
  end

  # Helper client function
  defp call_restock(warehouse_id, store_id, product_id, quantity) do
    GenServer.call(via_tuple(warehouse_id), {:restock, store_id, product_id, quantity})
  end

  # Helper to construct registry name
  def via_tuple(warehouse_id) do
    {:via, Registry, {EnterpriseShop.WarehouseRegistry, warehouse_id}}
  end

  # Server Callbacks

  @impl true
  def init(warehouse_id) do
    {:ok, %{warehouse_id: warehouse_id}}
  end

  @impl true
  def handle_call({:restock, store_id, product_id, quantity}, _from, state) do
    warehouse_id = state.warehouse_id

    # Execute restock inside a transaction to ensure atomic updates
    result =
      Repo.transaction(fn ->
        # 1. Lock and fetch warehouse stock
        warehouse_item =
          InventoryItem
          |> where(
            location_type: "warehouse",
            location_id: ^warehouse_id,
            product_id: ^product_id
          )
          |> lock("FOR UPDATE")
          |> Repo.one()

        warehouse_qty = if warehouse_item, do: warehouse_item.quantity, else: 0

        if warehouse_qty >= quantity do
          # 2. Deduct from warehouse
          Inventory.update_inventory_stock("warehouse", warehouse_id, product_id, -quantity)

          # 3. Add to store
          Inventory.update_inventory_stock("store", store_id, product_id, quantity)

          # 4. Broadcast the update for the real-time dashboard
          Phoenix.PubSub.broadcast(
            EnterpriseShop.PubSub,
            "inventory_updates",
            {:inventory_updated,
             %{
               product_id: product_id,
               store_id: store_id,
               warehouse_id: warehouse_id
             }}
          )

          :ok
        else
          # If warehouse doesn't have enough, we can't restock
          Repo.rollback(:insufficient_warehouse_stock)
        end
      end)

    case result do
      {:ok, :ok} ->
        {:reply, {:ok, :restocked}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
end

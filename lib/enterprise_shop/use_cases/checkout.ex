defmodule EnterpriseShop.UseCases.Checkout do
  @moduledoc """
  Checkout use case. Reserves store stock and creates orders.
  Triggers restocking if store stock drops below the threshold.
  """

  alias EnterpriseShop.Repo
  alias EnterpriseShop.Inventory
  alias EnterpriseShop.Sales
  alias EnterpriseShop.Schemas.Warehouse
  import Ecto.Query

  @doc """
  Executes the checkout process for a store and a map of products.
  items: %{product_id => quantity}
  """
  def execute(store_id, items) do
    Repo.transaction(fn ->
      # 1. Deduct stock from store for all items
      deduct_results =
        for {product_id, qty} <- items do
          case Inventory.update_inventory_stock("store", store_id, product_id, -qty) do
            {:ok, updated_item} ->
              {:ok, product_id, updated_item}

            {:error, :insufficient_stock} ->
              {:error, product_id}
          end
        end

      # 2. Check if any deduction failed
      failed = Enum.filter(deduct_results, &match?({:error, _}, &1))

      if failed != [] do
        # Roll back transaction if any item is out of stock
        {_, first_failed_product_id} = List.first(failed)

        # Trigger an immediate restock for the failed product to replenish it
        trigger_restock(store_id, first_failed_product_id)

        Repo.rollback({:insufficient_stock, first_failed_product_id})
      else
        # 3. Create the order
        {:ok, order} = Sales.create_order(store_id, items)

        # 4. Transition order from :new to :registered
        {:ok, registered_order} = Sales.update_order_state(order.id, :registered)

        # 5. Check if any purchased product is now below threshold and needs restocking
        store = Inventory.get_store!(store_id)

        for {product_id, _qty} <- items do
          item = Inventory.get_inventory_item("store", store_id, product_id)
          current_qty = if item, do: item.quantity, else: 0

          if current_qty < store.restock_threshold do
            trigger_restock(store_id, product_id)
          end
        end

        registered_order
      end
    end)
  end

  # Helper to trigger restock asynchronously using the REST API
  defp trigger_restock(store_id, product_id) do
    Task.start(fn ->
      # Find a warehouse belonging to the same enterprise as the store
      store = Inventory.get_store!(store_id)

      warehouse =
        Repo.one(
          from(w in Warehouse,
            where: w.enterprise_id == ^store.enterprise_id,
            limit: 1
          )
        )

      if warehouse do
        # Call the REST API to perform the restocking
        # Default restock quantity is 20 units
        url = "http://localhost:#{System.get_env("PORT") || "4000"}/api/v1/warehouse/restock"

        body = %{
          "store_id" => store_id,
          "warehouse_id" => warehouse.id,
          "product_id" => product_id,
          "quantity" => 20
        }

        # Retrieve client implementation (swapped to Mock in tests)
        client =
          Application.get_env(:enterprise_shop, :http_client, EnterpriseShop.HTTPClient.ReqImpl)

        case client.post(url, body) do
          {:ok, _} ->
            :ok

          other ->
            # Log failure but do not crash the checkout process
            IO.inspect(other, label: "Restock API call failed")
            :error
        end
      end
    end)
  end
end

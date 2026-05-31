defmodule EnterpriseShopWeb.API.WarehouseController do
  use EnterpriseShopWeb, :controller

  alias EnterpriseShop.UseCases.RestockStore

  @doc """
  REST endpoint to restock store inventory from a warehouse.
  Invoked by the store as an HTTP client.
  """
  def restock(conn, %{
        "warehouse_id" => warehouse_id,
        "store_id" => store_id,
        "product_id" => product_id,
        "quantity" => quantity
      }) do
    # Convert string parameters from HTTP request to integers
    warehouse_id = to_int(warehouse_id)
    store_id = to_int(store_id)
    product_id = to_int(product_id)
    quantity = to_int(quantity)

    case RestockStore.execute(warehouse_id, store_id, product_id, quantity) do
      {:ok, :restocked} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "ok", message: "Restocked successfully"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "error", message: to_string(reason)})
    end
  end

  # Helper to normalize integer parameters
  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
end

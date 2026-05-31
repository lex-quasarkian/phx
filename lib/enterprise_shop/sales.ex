defmodule EnterpriseShop.Sales do
  @moduledoc """
  The Sales context.
  """

  import Ecto.Query, warn: false
  alias EnterpriseShop.Repo
  alias EnterpriseShop.Catalog
  alias EnterpriseShop.Schemas.Order
  alias EnterpriseShop.Schemas.OrderLine

  @doc """
  Gets a single order with preloaded associations.
  """
  def get_order!(id) do
    Order
    |> preload([:order_lines, order_lines: :product])
    |> Repo.get!(id)
  end

  @doc """
  Creates an order from a cart/items map.
  items is a map of %{product_id => quantity}.
  """
  def create_order(store_id, items) do
    Repo.transaction(fn ->
      # Fetch product details for prices
      product_ids = Map.keys(items)
      products = Enum.map(product_ids, &Catalog.get_product!/1)
      product_map = Map.new(products, &{&1.id, &1})

      total_price =
        Enum.reduce(items, Decimal.new("0.00"), fn {product_id, quantity}, acc ->
          product = Map.fetch!(product_map, product_id)
          Decimal.add(acc, Decimal.mult(product.price, Decimal.new(quantity)))
        end)

      order =
        %Order{}
        |> Order.changeset(%{
          store_id: store_id,
          state: "new",
          total_price: total_price
        })
        |> Repo.insert!()

      for {product_id, quantity} <- items do
        product = Map.fetch!(product_map, product_id)

        %OrderLine{}
        |> OrderLine.changeset(%{
          order_id: order.id,
          product_id: product_id,
          quantity: quantity,
          price: product.price
        })
        |> Repo.insert!()
      end

      Repo.preload(order, order_lines: :product)
    end)
  end

  @doc """
  Updates the state of an order.
  """
  def update_order_state(order_id, new_state) do
    order = Repo.get!(Order, order_id)

    order
    |> Order.changeset(%{state: to_string(new_state)})
    |> Repo.update()
  end
end

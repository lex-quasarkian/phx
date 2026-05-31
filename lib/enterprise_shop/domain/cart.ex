defmodule EnterpriseShop.Domain.Cart do
  @moduledoc """
  Cart domain entity. Represents a customer's shopping cart.
  """

  defstruct items: %{}

  @type t :: %__MODULE__{
          items: %{any() => integer()}
        }

  @doc """
  Creates an empty Cart.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Adds an item to the cart with the specified quantity.
  """
  @spec add_item(t(), any(), integer()) :: t()
  def add_item(%__MODULE__{items: items} = cart, product_id, quantity \\ 1) do
    if quantity <= 0 do
      cart
    else
      current = Map.get(items, product_id, 0)
      %{cart | items: Map.put(items, product_id, current + quantity)}
    end
  end

  @doc """
  Removes or decreases the quantity of an item from the cart.
  """
  @spec remove_item(t(), any(), integer()) :: t()
  def remove_item(%__MODULE__{items: items} = cart, product_id, quantity \\ 1) do
    current = Map.get(items, product_id, 0)

    cond do
      current <= quantity ->
        %{cart | items: Map.delete(items, product_id)}

      true ->
        %{cart | items: Map.put(items, product_id, current - quantity)}
    end
  end

  @doc """
  Clears all items from the cart.
  """
  @spec clear(t()) :: t()
  def clear(_cart), do: %__MODULE__{}
end

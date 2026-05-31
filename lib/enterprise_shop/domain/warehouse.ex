defmodule EnterpriseShop.Domain.Warehouse do
  @moduledoc """
  Warehouse domain entity. Stores wholesale stock.
  """

  @enforce_keys [:id, :name]
  defstruct [:id, :name, inventory: %{}]

  @type t :: %__MODULE__{
          id: any(),
          name: String.t(),
          inventory: map()
        }

  @doc """
  Creates a new Warehouse entity.
  """
  @spec new(any(), String.t(), map()) :: t()
  def new(id, name, inventory \\ %{}) do
    %__MODULE__{
      id: id,
      name: name,
      inventory: inventory
    }
  end

  @doc """
  Checks if the warehouse has enough stock of a product.
  """
  @spec has_stock?(t(), any(), integer()) :: boolean()
  def has_stock?(%__MODULE__{inventory: inventory}, product_id, quantity) do
    Map.get(inventory, product_id, 0) >= quantity
  end

  @doc """
  Deducts stock from the warehouse. Returns {:ok, updated_warehouse} or {:error, :insufficient_stock}.
  """
  @spec deduct_stock(t(), any(), integer()) :: {:ok, t()} | {:error, :insufficient_stock}
  def deduct_stock(%__MODULE__{inventory: inventory} = warehouse, product_id, quantity) do
    current = Map.get(inventory, product_id, 0)

    if current >= quantity do
      updated_inventory = Map.put(inventory, product_id, current - quantity)
      {:ok, %{warehouse | inventory: updated_inventory}}
    else
      {:error, :insufficient_stock}
    end
  end

  @doc """
  Adds stock to the warehouse.
  """
  @spec add_stock(t(), any(), integer()) :: t()
  def add_stock(%__MODULE__{inventory: inventory} = warehouse, product_id, quantity) do
    current = Map.get(inventory, product_id, 0)
    updated_inventory = Map.put(inventory, product_id, current + quantity)
    %{warehouse | inventory: updated_inventory}
  end
end

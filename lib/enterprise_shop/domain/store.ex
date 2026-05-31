defmodule EnterpriseShop.Domain.Store do
  @moduledoc """
  Store domain entity. Represents the retail shopfront and holds stock.
  """

  @enforce_keys [:id, :name]
  defstruct [:id, :name, inventory: %{}, restock_threshold: 5]

  @type t :: %__MODULE__{
          id: any(),
          name: String.t(),
          inventory: map(),
          restock_threshold: integer()
        }

  @doc """
  Creates a new Store entity.
  """
  @spec new(any(), String.t(), map(), integer()) :: t()
  def new(id, name, inventory \\ %{}, restock_threshold \\ 5) do
    %__MODULE__{
      id: id,
      name: name,
      inventory: inventory,
      restock_threshold: restock_threshold
    }
  end

  @doc """
  Checks if a product needs restocking.
  Returns true if the current quantity is below the restock threshold.
  """
  @spec needs_restock?(t(), any()) :: boolean()
  def needs_restock?(%__MODULE__{inventory: inventory, restock_threshold: threshold}, product_id) do
    Map.get(inventory, product_id, 0) < threshold
  end

  @doc """
  Deducts stock from the store. Returns {:ok, updated_store} or {:error, :insufficient_stock}.
  """
  @spec deduct_stock(t(), any(), integer()) :: {:ok, t()} | {:error, :insufficient_stock}
  def deduct_stock(%__MODULE__{inventory: inventory} = store, product_id, quantity) do
    current = Map.get(inventory, product_id, 0)

    if current >= quantity do
      updated_inventory = Map.put(inventory, product_id, current - quantity)
      {:ok, %{store | inventory: updated_inventory}}
    else
      {:error, :insufficient_stock}
    end
  end

  @doc """
  Adds stock to the store.
  """
  @spec add_stock(t(), any(), integer()) :: t()
  def add_stock(%__MODULE__{inventory: inventory} = store, product_id, quantity) do
    current = Map.get(inventory, product_id, 0)
    updated_inventory = Map.put(inventory, product_id, current + quantity)
    %{store | inventory: updated_inventory}
  end
end

defmodule EnterpriseShop.Inventory do
  @moduledoc """
  The Inventory context.
  """

  import Ecto.Query, warn: false
  alias EnterpriseShop.Repo
  alias EnterpriseShop.Schemas.Warehouse
  alias EnterpriseShop.Schemas.Store
  alias EnterpriseShop.Schemas.InventoryItem

  def list_warehouses do
    Repo.all(Warehouse)
  end

  def get_warehouse!(id), do: Repo.get!(Warehouse, id)

  def create_warehouse(attrs \\ %{}) do
    %Warehouse{}
    |> Warehouse.changeset(attrs)
    |> Repo.insert()
  end

  def list_stores do
    Repo.all(Store)
  end

  def get_store!(id), do: Repo.get!(Store, id)

  def create_store(attrs \\ %{}) do
    %Store{}
    |> Store.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets an inventory item for a location and product.
  """
  def get_inventory_item(location_type, location_id, product_id) do
    Repo.get_by(InventoryItem,
      location_type: to_string(location_type),
      location_id: location_id,
      product_id: product_id
    )
  end

  @doc """
  Lists all inventory items for a given location, preloading the product.
  """
  def list_inventory_by_location(location_type, location_id) do
    InventoryItem
    |> where(location_type: ^to_string(location_type), location_id: ^location_id)
    |> preload(:product)
    |> Repo.all()
  end

  @doc """
  Creates or sets up an initial inventory item.
  """
  def create_inventory_item(attrs \\ %{}) do
    %InventoryItem{}
    |> InventoryItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the stock of a product at a location (store or warehouse).
  change_quantity can be positive (adding stock) or negative (deducting stock).
  Runs within a transaction using database locks to prevent race conditions.
  """
  def update_inventory_stock(location_type, location_id, product_id, change_quantity) do
    location_type_str = to_string(location_type)

    Repo.transaction(fn ->
      item =
        InventoryItem
        |> where(
          location_type: ^location_type_str,
          location_id: ^location_id,
          product_id: ^product_id
        )
        |> lock("FOR UPDATE")
        |> Repo.one()

      case item do
        nil ->
          if change_quantity >= 0 do
            %InventoryItem{}
            |> InventoryItem.changeset(%{
              location_type: location_type_str,
              location_id: location_id,
              product_id: product_id,
              quantity: change_quantity
            })
            |> Repo.insert!()
          else
            Repo.rollback(:insufficient_stock)
          end

        %InventoryItem{quantity: quantity} = item ->
          new_quantity = quantity + change_quantity

          if new_quantity >= 0 do
            item
            |> InventoryItem.changeset(%{quantity: new_quantity})
            |> Repo.update!()
          else
            Repo.rollback(:insufficient_stock)
          end
      end
    end)
  end
end

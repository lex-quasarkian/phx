defmodule EnterpriseShop.Schemas.InventoryItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "inventory_items" do
    # "warehouse" or "store"
    field :location_type, :string
    field :location_id, :integer
    field :quantity, :integer, default: 0
    belongs_to :product, EnterpriseShop.Schemas.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(inventory_item, attrs) do
    inventory_item
    |> cast(attrs, [:product_id, :location_type, :location_id, :quantity])
    |> validate_required([:product_id, :location_type, :location_id, :quantity])
    |> validate_inclusion(:location_type, ["warehouse", "store"])
    |> unique_constraint([:product_id, :location_type, :location_id],
      name: :inventory_items_product_id_location_type_location_id_index
    )
  end
end

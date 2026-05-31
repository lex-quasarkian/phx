defmodule EnterpriseShop.Schemas.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :sku, :string
    field :price, :decimal

    timestamps(type: :utc_datetime)
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :sku, :price])
    |> validate_required([:name, :sku, :price])
    |> unique_constraint(:sku)
  end
end

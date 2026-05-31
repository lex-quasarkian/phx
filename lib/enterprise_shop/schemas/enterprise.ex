defmodule EnterpriseShop.Schemas.Enterprise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "enterprises" do
    field :name, :string
    has_many :warehouses, EnterpriseShop.Schemas.Warehouse
    has_many :stores, EnterpriseShop.Schemas.Store

    timestamps(type: :utc_datetime)
  end

  def changeset(enterprise, attrs) do
    enterprise
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end

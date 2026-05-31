defmodule EnterpriseShop.Schemas.Warehouse do
  use Ecto.Schema
  import Ecto.Changeset

  schema "warehouses" do
    field :name, :string
    belongs_to :enterprise, EnterpriseShop.Schemas.Enterprise

    timestamps(type: :utc_datetime)
  end

  def changeset(warehouse, attrs) do
    warehouse
    |> cast(attrs, [:name, :enterprise_id])
    |> validate_required([:name, :enterprise_id])
  end
end

defmodule EnterpriseShop.Schemas.Store do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stores" do
    field :name, :string
    field :restock_threshold, :integer, default: 5
    belongs_to :enterprise, EnterpriseShop.Schemas.Enterprise

    timestamps(type: :utc_datetime)
  end

  def changeset(store, attrs) do
    store
    |> cast(attrs, [:name, :enterprise_id, :restock_threshold])
    |> validate_required([:name, :enterprise_id, :restock_threshold])
  end
end

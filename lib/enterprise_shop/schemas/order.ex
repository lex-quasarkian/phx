defmodule EnterpriseShop.Schemas.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field :state, :string, default: "new"
    field :total_price, :decimal
    belongs_to :store, EnterpriseShop.Schemas.Store
    has_many :order_lines, EnterpriseShop.Schemas.OrderLine

    timestamps(type: :utc_datetime)
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:state, :total_price, :store_id])
    |> validate_required([:state, :total_price, :store_id])
    |> validate_inclusion(:state, ["new", "registered", "granted", "shipped", "cancelled"])
  end
end

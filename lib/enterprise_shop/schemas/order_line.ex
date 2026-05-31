defmodule EnterpriseShop.Schemas.OrderLine do
  use Ecto.Schema
  import Ecto.Changeset

  schema "order_lines" do
    field :quantity, :integer
    field :price, :decimal
    belongs_to :order, EnterpriseShop.Schemas.Order
    belongs_to :product, EnterpriseShop.Schemas.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(order_line, attrs) do
    order_line
    |> cast(attrs, [:quantity, :price, :order_id, :product_id])
    |> validate_required([:quantity, :price, :order_id, :product_id])
    |> unique_constraint([:order_id, :product_id])
  end
end

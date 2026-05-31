defmodule EnterpriseShop.Catalog do
  @moduledoc """
  The Catalog context.
  """

  import Ecto.Query, warn: false
  alias EnterpriseShop.Repo
  alias EnterpriseShop.Schemas.Product

  @doc """
  Returns the list of products.
  """
  def list_products do
    Repo.all(Product)
  end

  @doc """
  Gets a single product.
  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a product.
  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end
end

defmodule EnterpriseShop.Domain.Enterprise do
  @moduledoc """
  Enterprise domain entity. Logically groups warehouses and stores.
  """

  @enforce_keys [:id, :name]
  defstruct [:id, :name, warehouses: [], stores: []]

  @type t :: %__MODULE__{
          id: any(),
          name: String.t(),
          warehouses: list(),
          stores: list()
        }

  @doc """
  Creates a new Enterprise entity.
  """
  @spec new(any(), String.t(), list(), list()) :: t()
  def new(id, name, warehouses \\ [], stores \\ []) do
    %__MODULE__{
      id: id,
      name: name,
      warehouses: warehouses,
      stores: stores
    }
  end
end

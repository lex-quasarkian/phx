defmodule EnterpriseShop.Domain.Order do
  @moduledoc """
  Order domain entity. Manages the lifecycle of an order using the State pattern.
  """

  @enforce_keys [:id, :items]
  defstruct [:id, :items, state: :new]

  @type state :: :new | :registered | :granted | :shipped | :cancelled

  @type t :: %__MODULE__{
          id: any(),
          items: %{any() => integer()},
          state: state()
        }

  @doc """
  Creates a new Order entity in the `:new` state.
  """
  @spec new(any(), %{any() => integer()}) :: t()
  def new(id, items) do
    %__MODULE__{
      id: id,
      items: items,
      state: :new
    }
  end

  @doc """
  Triggers a state transition for the order based on an action.
  """
  @spec transition(t(), :register | :grant | :ship | :cancel) ::
          {:ok, t()} | {:error, :invalid_transition}
  def transition(%__MODULE__{state: :new} = order, :register) do
    {:ok, %{order | state: :registered}}
  end

  def transition(%__MODULE__{state: :registered} = order, :grant) do
    {:ok, %{order | state: :granted}}
  end

  def transition(%__MODULE__{state: :registered} = order, :cancel) do
    {:ok, %{order | state: :cancelled}}
  end

  def transition(%__MODULE__{state: :granted} = order, :ship) do
    {:ok, %{order | state: :shipped}}
  end

  def transition(%__MODULE__{state: :granted} = order, :cancel) do
    {:ok, %{order | state: :cancelled}}
  end

  def transition(_order, _invalid_action) do
    {:error, :invalid_transition}
  end
end

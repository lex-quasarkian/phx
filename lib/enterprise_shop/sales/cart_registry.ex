defmodule EnterpriseShop.Sales.CartRegistry do
  use GenServer

  alias EnterpriseShop.Domain.Cart

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Gets the cart for a specific session.
  """
  def get_cart(registry \\ __MODULE__, session_id) do
    GenServer.call(registry, {:get, session_id})
  end

  @doc """
  Updates the cart for a specific session by applying a function.
  """
  def update_cart(registry \\ __MODULE__, session_id, fun) do
    GenServer.call(registry, {:update, session_id, fun})
  end

  @doc """
  Clears the cart for a specific session.
  """
  def clear_cart(registry \\ __MODULE__, session_id) do
    GenServer.call(registry, {:clear, session_id})
  end

  # Server Callbacks

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get, session_id}, _from, state) do
    cart = Map.get(state, session_id, Cart.new())
    {:reply, cart, Map.put(state, session_id, cart)}
  end

  @impl true
  def handle_call({:update, session_id, fun}, _from, state) do
    cart = Map.get(state, session_id, Cart.new())
    updated_cart = fun.(cart)
    {:reply, updated_cart, Map.put(state, session_id, updated_cart)}
  end

  @impl true
  def handle_call({:clear, session_id}, _from, state) do
    {:reply, Cart.new(), Map.put(state, session_id, Cart.new())}
  end
end

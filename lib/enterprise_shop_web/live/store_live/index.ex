defmodule EnterpriseShopWeb.StoreLive.Index do
  use EnterpriseShopWeb, :live_view

  alias EnterpriseShop.Catalog
  alias EnterpriseShop.Inventory
  alias EnterpriseShop.Sales.CartRegistry
  alias EnterpriseShop.Domain.Cart

  @impl true
  def mount(_params, session, socket) do
    session_id = Map.get(session, "session_id")
    stores = Inventory.list_stores()
    current_store = List.first(stores)

    # Fetch initial inventory for the current store
    inventory_map = get_inventory_map(current_store)

    # Read cart to show count
    cart = CartRegistry.get_cart(session_id)
    cart_count = get_cart_count(cart)

    products = Catalog.list_products()

    # Subscribe to inventory updates for real-time dashboard and store stock sync
    if connected?(socket) do
      Phoenix.PubSub.subscribe(EnterpriseShop.PubSub, "inventory_updates")
    end

    socket =
      socket
      |> assign(:page_title, "Store Catalog")
      |> assign(:session_id, session_id)
      |> assign(:stores, stores)
      |> assign(:current_store, current_store)
      |> assign(:inventory, inventory_map)
      |> assign(:cart_count, cart_count)
      |> stream(:products, products)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_store", %{"store_id" => store_id}, socket) do
    store_id = String.to_integer(store_id)
    store = Enum.find(socket.assigns.stores, &(&1.id == store_id))
    inventory_map = get_inventory_map(store)

    {:noreply,
     socket
     |> assign(:current_store, store)
     |> assign(:inventory, inventory_map)}
  end

  @impl true
  def handle_event("add_to_cart", %{"product-id" => product_id}, socket) do
    product_id = String.to_integer(product_id)

    cart =
      CartRegistry.update_cart(socket.assigns.session_id, fn cart ->
        Cart.add_item(cart, product_id, 1)
      end)

    {:noreply,
     socket
     |> assign(:cart_count, get_cart_count(cart))
     |> put_flash(:info, "Added item to cart")}
  end

  @impl true
  def handle_info({:inventory_updated, %{store_id: store_id}}, socket) do
    # If the inventory update is for our current store, refresh inventory stock levels
    if socket.assigns.current_store && socket.assigns.current_store.id == store_id do
      inventory_map = get_inventory_map(socket.assigns.current_store)
      {:noreply, assign(socket, :inventory, inventory_map)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  # Helper functions

  defp get_inventory_map(nil), do: %{}

  defp get_inventory_map(store) do
    Inventory.list_inventory_by_location("store", store.id)
    |> Map.new(fn item -> {item.product_id, item.quantity} end)
  end

  defp get_cart_count(cart) do
    Enum.reduce(cart.items, 0, fn {_, qty}, acc -> acc + qty end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container py-4">
        <!-- Header Section -->
        <div class="row align-items-center mb-4 pb-3 border-bottom">
          <div class="col-md-6">
            <h1 class="display-5 fw-bold text-dark">Storefront Catalog</h1>
            <p class="text-muted mb-0">Browse and purchase products from our local stores.</p>
          </div>
          <div class="col-md-6 text-md-end mt-3 mt-md-0">
            <.link navigate={~p"/cart"} class="btn btn-outline-primary position-relative px-4 py-2">
              <.icon name="hero-shopping-cart" class="w-5 h-5 me-2 align-text-bottom" /> Shopping Cart
              <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger">
                {@cart_count}
              </span>
            </.link>
            <.link navigate={~p"/warehouse/dashboard"} class="btn btn-secondary ms-2 px-4 py-2">
              <.icon name="hero-presentation-chart-line" class="w-5 h-5 me-2 align-text-bottom" />
              Dashboard
            </.link>
          </div>
        </div>
        
    <!-- Store Switcher -->
        <div class="card mb-4 border-0 shadow-sm bg-light">
          <div class="card-body py-3 px-4 d-flex align-items-center justify-content-between flex-wrap gap-3">
            <div class="d-flex align-items-center">
              <.icon name="hero-building-storefront" class="w-6 h-6 text-primary me-2" />
              <div>
                <span class="text-muted small d-block">Browsing Location:</span>
                <strong class="text-dark">
                  {(@current_store && @current_store.name) || "No Store Selected"}
                </strong>
              </div>
            </div>

            <%= if @stores != [] do %>
              <form phx-change="select_store" class="d-flex align-items-center">
                <label for="store_id" class="me-2 mb-0 text-muted small">Switch Store:</label>
                <select name="store_id" id="store_id" class="form-select form-select-sm w-auto">
                  <%= for store <- @stores do %>
                    <option
                      value={store.id}
                      selected={@current_store && store.id == @current_store.id}
                    >
                      {store.name}
                    </option>
                  <% end %>
                </select>
              </form>
            <% end %>
          </div>
        </div>
        
    <!-- Product Grid -->
        <%= if @current_store do %>
          <div id="products-grid" class="row row-cols-1 row-cols-md-3 g-4" phx-update="stream">
            <div :for={{id, product} <- @streams.products} id={id} class="col">
              <div class="card h-100 border-0 shadow-sm transition-hover">
                <div class="card-body d-flex flex-column p-4">
                  <div class="d-flex justify-content-between align-items-start mb-3">
                    <h5 class="card-title fw-bold mb-0 text-dark">{product.name}</h5>
                    <span class="badge bg-light text-primary font-monospace">{product.sku}</span>
                  </div>

                  <p class="card-text text-muted flex-grow-1 small">
                    This premium product is available for immediate pick-up or shipment.
                  </p>

                  <div class="d-flex justify-content-between align-items-center mt-3 pt-3 border-top">
                    <div>
                      <span class="text-muted small d-block">Price:</span>
                      <strong class="fs-5 text-dark">${product.price}</strong>
                    </div>
                    <div class="text-end">
                      <span class="text-muted small d-block">Stock:</span>
                      <% stock_qty = Map.get(@inventory, product.id, 0) %>
                      <%= cond do %>
                        <% stock_qty == 0 -> %>
                          <span class="badge bg-danger">Out of Stock</span>
                        <% stock_qty < @current_store.restock_threshold -> %>
                          <span class="badge bg-warning text-dark">{stock_qty} Low Stock</span>
                        <% true -> %>
                          <span class="badge bg-success">{stock_qty} Available</span>
                      <% end %>
                    </div>
                  </div>

                  <div class="mt-4">
                    <%= if stock_qty > 0 do %>
                      <button
                        phx-click="add_to_cart"
                        phx-value-product-id={product.id}
                        id={"add-to-cart-btn-#{product.id}"}
                        class="btn btn-primary w-100 d-flex align-items-center justify-content-center py-2"
                      >
                        <.icon name="hero-plus" class="w-4 h-4 me-2" /> Add to Cart
                      </button>
                    <% else %>
                      <button
                        class="btn btn-secondary w-100 py-2"
                        disabled
                        id={"add-to-cart-btn-#{product.id}-disabled"}
                      >
                        Out of Stock
                      </button>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <div class="alert alert-warning text-center py-4" role="alert">
            <.icon name="hero-exclamation-triangle" class="w-8 h-8 text-warning mb-2" />
            <h4 class="alert-heading">No Stores Configured!</h4>
            <p class="mb-0">Please run seeds to set up initial enterprise stores.</p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end

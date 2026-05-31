defmodule EnterpriseShopWeb.CartLive.Show do
  use EnterpriseShopWeb, :live_view

  alias EnterpriseShop.Catalog
  alias EnterpriseShop.Inventory
  alias EnterpriseShop.Sales.CartRegistry
  alias EnterpriseShop.Domain.Cart
  alias EnterpriseShop.UseCases.Checkout

  @impl true
  def mount(_params, session, socket) do
    session_id = Map.get(session, "session_id")
    stores = Inventory.list_stores()
    selected_store_id = if stores != [], do: List.first(stores).id, else: nil

    socket =
      socket
      |> assign(:page_title, "Shopping Cart")
      |> assign(:session_id, session_id)
      |> assign(:stores, stores)
      |> assign(:selected_store_id, selected_store_id)

    {:ok, assign_cart_details(socket)}
  end

  @impl true
  def handle_event("select_store", %{"store_id" => store_id}, socket) do
    {:noreply, assign(socket, :selected_store_id, String.to_integer(store_id))}
  end

  @impl true
  def handle_event("increment_qty", %{"product-id" => product_id}, socket) do
    product_id = String.to_integer(product_id)

    CartRegistry.update_cart(socket.assigns.session_id, fn cart ->
      Cart.add_item(cart, product_id, 1)
    end)

    {:noreply, assign_cart_details(socket)}
  end

  @impl true
  def handle_event("decrement_qty", %{"product-id" => product_id}, socket) do
    product_id = String.to_integer(product_id)

    CartRegistry.update_cart(socket.assigns.session_id, fn cart ->
      Cart.remove_item(cart, product_id, 1)
    end)

    {:noreply, assign_cart_details(socket)}
  end

  @impl true
  def handle_event("remove_item", %{"product-id" => product_id}, socket) do
    product_id = String.to_integer(product_id)

    CartRegistry.update_cart(socket.assigns.session_id, fn cart ->
      # Remove completely by subtracting a large amount
      Cart.remove_item(cart, product_id, 999_999)
    end)

    {:noreply, assign_cart_details(socket)}
  end

  @impl true
  def handle_event("place_order", _params, socket) do
    store_id = socket.assigns.selected_store_id
    cart = socket.assigns.cart

    if store_id == nil do
      {:noreply, put_flash(socket, :error, "Please select a store first.")}
    else
      case Checkout.execute(store_id, cart.items) do
        {:ok, order} ->
          CartRegistry.clear_cart(socket.assigns.session_id)

          {:noreply,
           socket
           |> put_flash(:info, "Order placed successfully! Order status: #{order.state}")
           |> push_navigate(to: ~p"/store")}

        {:error, {:insufficient_stock, product_id}} ->
          product = Catalog.get_product!(product_id)

          {:noreply,
           socket
           |> put_flash(
             :error,
             "Insufficient stock for '#{product.name}'. A restock request has been dispatched to the warehouse."
           )
           |> assign_cart_details()}
      end
    end
  end

  # Helper to load product info and calculate totals
  defp assign_cart_details(socket) do
    cart = CartRegistry.get_cart(socket.assigns.session_id)
    products = Catalog.list_products()
    product_map = Map.new(products, &{&1.id, &1})

    cart_items =
      Enum.map(cart.items, fn {product_id, qty} ->
        product = Map.get(product_map, product_id)

        %{
          product: product,
          quantity: qty,
          subtotal:
            if(product,
              do: Decimal.mult(product.price, Decimal.new(qty)),
              else: Decimal.new("0.00")
            )
        }
      end)
      |> Enum.filter(&(&1.product != nil))
      |> Enum.sort_by(& &1.product.name)

    total_price =
      Enum.reduce(cart_items, Decimal.new("0.00"), fn item, acc ->
        Decimal.add(acc, item.subtotal)
      end)

    socket
    |> assign(:cart, cart)
    |> assign(:cart_items, cart_items)
    |> assign(:total_price, total_price)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="container py-4">
        <!-- Header -->
        <div class="row align-items-center mb-4 pb-3 border-bottom">
          <div class="col-md-6">
            <.link
              navigate={~p"/store"}
              class="text-decoration-none small text-primary d-inline-flex align-items-center mb-2"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4 me-1" /> Back to Catalog
            </.link>
            <h1 class="display-6 fw-bold text-dark">Shopping Cart</h1>
          </div>
        </div>

        <%= if @cart_items == [] do %>
          <div class="card border-0 shadow-sm py-5 text-center">
            <div class="card-body">
              <.icon name="hero-shopping-bag" class="w-16 h-16 text-muted mb-3" />
              <h3 class="fw-bold text-dark">Your cart is empty</h3>
              <p class="text-muted mb-4">Add some items from our catalog to get started.</p>
              <.link navigate={~p"/store"} class="btn btn-primary px-4 py-2">
                Continue Shopping
              </.link>
            </div>
          </div>
        <% else %>
          <div class="row g-4">
            <!-- Cart Items List -->
            <div class="col-lg-8">
              <div class="card border-0 shadow-sm p-4">
                <h4 class="fw-bold text-dark mb-4">Items in Cart</h4>
                <div class="table-responsive">
                  <table class="table align-middle">
                    <thead>
                      <tr class="text-muted small">
                        <th>Product Details</th>
                        <th class="text-center">Quantity</th>
                        <th class="text-end">Subtotal</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for item <- @cart_items do %>
                        <tr id={"cart-item-#{item.product.id}"}>
                          <td>
                            <h6 class="fw-bold text-dark mb-1">{item.product.name}</h6>
                            <span class="badge bg-light text-primary font-monospace small">
                              {item.product.sku}
                            </span>
                          </td>
                          <td>
                            <div class="d-flex align-items-center justify-content-center">
                              <button
                                phx-click="decrement_qty"
                                phx-value-product-id={item.product.id}
                                id={"dec-qty-btn-#{item.product.id}"}
                                class="btn btn-sm btn-outline-secondary rounded-circle p-1 d-flex align-items-center justify-content-center"
                                style="width: 28px; height: 28px;"
                              >
                                <.icon name="hero-minus" class="w-3 h-3" />
                              </button>
                              <span class="mx-3 fw-bold">{item.quantity}</span>
                              <button
                                phx-click="increment_qty"
                                phx-value-product-id={item.product.id}
                                id={"inc-qty-btn-#{item.product.id}"}
                                class="btn btn-sm btn-outline-secondary rounded-circle p-1 d-flex align-items-center justify-content-center"
                                style="width: 28px; height: 28px;"
                              >
                                <.icon name="hero-plus" class="w-3 h-3" />
                              </button>
                            </div>
                          </td>
                          <td class="text-end fw-bold text-dark">${item.subtotal}</td>
                          <td class="text-end">
                            <button
                              phx-click="remove_item"
                              phx-value-product-id={item.product.id}
                              id={"remove-item-btn-#{item.product.id}"}
                              class="btn btn-sm btn-link text-danger p-0"
                            >
                              <.icon name="hero-trash" class="w-5 h-5" />
                            </button>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
            
    <!-- Order Summary & Checkout -->
            <div class="col-lg-4">
              <div class="card border-0 shadow-sm p-4 bg-light">
                <h4 class="fw-bold text-dark mb-4">Order Summary</h4>
                
    <!-- Store Switcher -->
                <div class="mb-4">
                  <label for="checkout_store_id" class="form-label text-muted small fw-bold">
                    Select Checkout Store:
                  </label>
                  <select
                    phx-change="select_store"
                    id="checkout_store_id"
                    name="store_id"
                    class="form-select form-select-sm"
                  >
                    <%= for store <- @stores do %>
                      <option value={store.id} selected={store.id == @selected_store_id}>
                        {store.name}
                      </option>
                    <% end %>
                  </select>
                </div>

                <div class="d-flex justify-content-between mb-2">
                  <span class="text-muted">Total Price</span>
                  <strong class="fs-5 text-dark">${@total_price}</strong>
                </div>

                <div class="mt-4 pt-3 border-top">
                  <button
                    phx-click="place_order"
                    id="place-order"
                    class="btn btn-primary w-100 py-3 d-flex align-items-center justify-content-center fw-bold"
                  >
                    <.icon name="hero-check" class="w-5 h-5 me-2" /> Place Order
                  </button>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end

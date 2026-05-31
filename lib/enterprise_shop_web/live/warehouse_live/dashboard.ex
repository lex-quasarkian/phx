defmodule EnterpriseShopWeb.WarehouseLive.Dashboard do
  use EnterpriseShopWeb, :live_view

  alias EnterpriseShop.Inventory
  alias EnterpriseShop.Repo
  alias EnterpriseShop.Schemas.InventoryItem
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(EnterpriseShop.PubSub, "inventory_updates")
    end

    socket =
      socket
      |> assign(:page_title, "Warehouse Dashboard")

    {:ok, assign_dashboard_data(socket)}
  end

  @impl true
  def handle_info({:inventory_updated, _meta}, socket) do
    # When receiving PubSub update, refresh the dashboard data
    {:noreply, assign_dashboard_data(socket)}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  # Helper to load dashboard inventory data
  defp assign_dashboard_data(socket) do
    warehouses = Inventory.list_warehouses()
    stores = Inventory.list_stores()

    # Load all inventory items with preloaded products
    items =
      InventoryItem
      |> preload(:product)
      |> Repo.all()

    # Map inventory items to warehouses
    warehouses_data =
      Enum.map(warehouses, fn w ->
        w_items =
          Enum.filter(items, &(&1.location_type == "warehouse" and &1.location_id == w.id))

        %{warehouse: w, items: w_items}
      end)

    # Map inventory items to stores
    stores_data =
      Enum.map(stores, fn s ->
        s_items =
          Enum.filter(items, &(&1.location_type == "store" and &1.location_id == s.id))

        %{store: s, items: s_items}
      end)

    socket
    |> assign(:warehouses_data, warehouses_data)
    |> assign(:stores_data, stores_data)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container py-4">
        <!-- Header -->
        <div class="row align-items-center mb-4 pb-3 border-bottom">
          <div class="col-md-6">
            <h1 class="display-5 fw-bold text-dark">Enterprise Dashboard</h1>
            <p class="text-muted mb-0">Real-time tracking of warehouse and store inventory levels.</p>
          </div>
          <div class="col-md-6 text-md-end mt-3 mt-md-0">
            <.link navigate={~p"/store"} class="btn btn-outline-primary px-4 py-2 me-2">
              <.icon name="hero-building-storefront" class="w-5 h-5 me-2 align-text-bottom" />
              Visit Store
            </.link>
            <span class="badge bg-success p-2 d-inline-flex align-items-center">
              <span class="spinner-grow spinner-grow-sm me-2" role="status" aria-hidden="true"></span>
              Live Sync Enabled
            </span>
          </div>
        </div>

        <div class="row g-4">
          <!-- Warehouses Inventory column -->
          <div class="col-lg-6">
            <div class="card border-0 shadow-sm p-4 h-100">
              <h3 class="fw-bold text-dark mb-4 d-flex align-items-center">
                <.icon name="hero-archive-box" class="w-6 h-6 text-primary me-2" />
                Warehouses (Wholesale)
              </h3>

              <%= if @warehouses_data == [] do %>
                <div class="text-center py-5 text-muted">
                  No warehouses registered.
                </div>
              <% else %>
                <%= for %{warehouse: w, items: items} <- @warehouses_data do %>
                  <div class="card mb-4 border border-light shadow-sm" id={"warehouse-card-#{w.id}"}>
                    <div class="card-header bg-white py-3">
                      <h5 class="fw-bold text-dark mb-0">{w.name}</h5>
                    </div>
                    <div class="card-body p-0">
                      <div class="table-responsive">
                        <table class="table align-middle mb-0">
                          <thead class="table-light text-muted small">
                            <tr>
                              <th class="ps-3">Product</th>
                              <th>SKU</th>
                              <th class="text-end pe-3">In Stock</th>
                            </tr>
                          </thead>
                          <tbody>
                            <%= if items == [] do %>
                              <tr>
                                <td colspan="3" class="text-center py-4 text-muted small">
                                  No inventory recorded.
                                </td>
                              </tr>
                            <% else %>
                              <%= for item <- items do %>
                                <tr id={"wh-item-#{w.id}-#{item.product.id}"}>
                                  <td class="ps-3 fw-bold text-dark">{item.product.name}</td>
                                  <td>
                                    <span class="badge bg-light text-secondary font-monospace">
                                      {item.product.sku}
                                    </span>
                                  </td>
                                  <td class="text-end pe-3 fw-bold fs-6">
                                    <%= if item.quantity == 0 do %>
                                      <span class="text-danger">0</span>
                                    <% else %>
                                      <span class="text-success">{item.quantity}</span>
                                    <% end %>
                                  </td>
                                </tr>
                              <% end %>
                            <% end %>
                          </tbody>
                        </table>
                      </div>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>
          
    <!-- Stores Inventory column -->
          <div class="col-lg-6">
            <div class="card border-0 shadow-sm p-4 h-100">
              <h3 class="fw-bold text-dark mb-4 d-flex align-items-center">
                <.icon name="hero-building-storefront" class="w-6 h-6 text-primary me-2" />
                Retail Stores (Shopfloor)
              </h3>

              <%= if @stores_data == [] do %>
                <div class="text-center py-5 text-muted">
                  No stores registered.
                </div>
              <% else %>
                <%= for %{store: s, items: items} <- @stores_data do %>
                  <div class="card mb-4 border border-light shadow-sm" id={"store-card-#{s.id}"}>
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                      <h5 class="fw-bold text-dark mb-0">{s.name}</h5>
                      <span class="badge bg-light text-muted small">
                        Restock threshold: {s.restock_threshold}
                      </span>
                    </div>
                    <div class="card-body p-0">
                      <div class="table-responsive">
                        <table class="table align-middle mb-0">
                          <thead class="table-light text-muted small">
                            <tr>
                              <th class="ps-3">Product</th>
                              <th>SKU</th>
                              <th class="text-end pe-3">In Stock</th>
                            </tr>
                          </thead>
                          <tbody>
                            <%= if items == [] do %>
                              <tr>
                                <td colspan="3" class="text-center py-4 text-muted small">
                                  No inventory recorded.
                                </td>
                              </tr>
                            <% else %>
                              <%= for item <- items do %>
                                <tr id={"store-item-#{s.id}-#{item.product.id}"}>
                                  <td class="ps-3 fw-bold text-dark">{item.product.name}</td>
                                  <td>
                                    <span class="badge bg-light text-secondary font-monospace">
                                      {item.product.sku}
                                    </span>
                                  </td>
                                  <td class="text-end pe-3 fw-bold fs-6">
                                    <%= cond do %>
                                      <% item.quantity == 0 -> %>
                                        <span class="text-danger">0 (Out of stock)</span>
                                      <% item.quantity < s.restock_threshold -> %>
                                        <span class="text-warning">{item.quantity} (Low stock)</span>
                                      <% true -> %>
                                        <span class="text-success">{item.quantity}</span>
                                    <% end %>
                                  </td>
                                </tr>
                              <% end %>
                            <% end %>
                          </tbody>
                        </table>
                      </div>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end

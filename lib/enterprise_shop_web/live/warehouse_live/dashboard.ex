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
      |> assign(:selected_product_id, nil)

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

  @impl true
  def handle_event(
        "manual_restock",
        %{"store-id" => store_id, "product-id" => product_id},
        socket
      ) do
    store_id = String.to_integer(store_id)
    product_id = String.to_integer(product_id)

    store = Inventory.get_store!(store_id)

    # Find the corresponding warehouse for the store (same enterprise)
    warehouse =
      Repo.one(
        from(w in EnterpriseShop.Schemas.Warehouse,
          where: w.enterprise_id == ^store.enterprise_id,
          limit: 1
        )
      )

    if warehouse == nil do
      {:noreply,
       put_flash(socket, :error, "No warehouse configured for this store's enterprise.")}
    else
      case EnterpriseShop.UseCases.RestockStore.execute(warehouse.id, store_id, product_id, 10) do
        {:ok, :restocked} ->
          {:noreply, put_flash(socket, :info, "Successfully restocked 10 units from warehouse!")}

        {:error, :insufficient_warehouse_stock} ->
          {:noreply,
           put_flash(socket, :error, "Restock failed: Insufficient warehouse inventory!")}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Restock failed: #{reason}")}
      end
    end
  end

  @impl true
  def handle_event("toggle_highlight", %{"product-id" => product_id}, socket) do
    product_id = String.to_integer(product_id)

    new_selected =
      if socket.assigns.selected_product_id == product_id do
        nil
      else
        product_id
      end

    {:noreply, assign(socket, :selected_product_id, new_selected)}
  end

  @impl true
  def handle_event("clear_highlight", _params, socket) do
    {:noreply, assign(socket, :selected_product_id, nil)}
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
          items
          |> Enum.filter(&(&1.location_type == "warehouse" and &1.location_id == w.id))
          |> Enum.sort_by(& &1.product.name)

        %{warehouse: w, items: w_items}
      end)

    # Map inventory items to stores
    stores_data =
      Enum.map(stores, fn s ->
        s_items =
          items
          |> Enum.filter(&(&1.location_type == "store" and &1.location_id == s.id))
          |> Enum.sort_by(& &1.product.name)

        %{store: s, items: s_items}
      end)
      |> Enum.sort_by(& &1.store.id)

    # Calculate total product quantities for each location
    warehouses_totals =
      Map.new(warehouses_data, fn %{warehouse: w, items: items} ->
        total = Enum.reduce(items, 0, fn item, acc -> acc + item.quantity end)
        {w.id, total}
      end)

    stores_totals =
      Map.new(stores_data, fn %{store: s, items: items} ->
        total = Enum.reduce(items, 0, fn item, acc -> acc + item.quantity end)
        {s.id, total}
      end)

    # Find the specific product IDs dynamically
    all_products = Repo.all(EnterpriseShop.Schemas.Product)

    pointer_product =
      Enum.find(
        all_products,
        &(&1.sku == "LASER-001" or String.contains?(String.downcase(&1.name), "pointer"))
      )

    boots_product =
      Enum.find(
        all_products,
        &(&1.sku == "BOOTS-002" or String.contains?(String.downcase(&1.name), "boot"))
      )

    generator_product =
      Enum.find(
        all_products,
        &(&1.sku == "WORM-003" or String.contains?(String.downcase(&1.name), "generator"))
      )

    pointer_id = (pointer_product && pointer_product.id) || 1
    boots_id = (boots_product && boots_product.id) || 2
    generator_id = (generator_product && generator_product.id) || 3

    socket
    |> assign(:warehouses_data, warehouses_data)
    |> assign(:stores_data, stores_data)
    |> assign(:warehouses_totals, warehouses_totals)
    |> assign(:stores_totals, stores_totals)
    |> assign(:pointer_id, pointer_id)
    |> assign(:boots_id, boots_id)
    |> assign(:generator_id, generator_id)
  end

  defp product_image_name(product) do
    cond do
      String.contains?(product.sku, "LASER") or
        String.contains?(String.downcase(product.name), "laser") or
          String.contains?(String.downcase(product.name), "pointer") ->
        "pointer.png"

      String.contains?(product.sku, "BOOTS") or
        String.contains?(String.downcase(product.name), "boot") or
          String.contains?(String.downcase(product.name), "gravity") ->
        "boots.png"

      String.contains?(product.sku, "WORM") or
        String.contains?(String.downcase(product.name), "wormhole") or
          String.contains?(String.downcase(product.name), "generator") ->
        "generator.png"

      true ->
        "pointer.png"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
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
        
    <!-- Interactive Map Section -->
        <div
          class="card border-0 shadow-lg mb-5 text-white overflow-hidden"
          style="background: linear-gradient(135deg, #111827 0%, #1f2937 100%); min-height: 380px; position: relative; border-radius: 16px;"
        >
          <!-- Map Grid Overlay -->
          <div
            class="position-absolute inset-0 opacity-10"
            style="background-image: radial-gradient(#ffffff 1px, transparent 1px); background-size: 20px 20px; top:0; left:0; width:100%; height:100%;"
          >
          </div>

          <div
            class="card-body p-4 d-flex flex-column justify-content-between position-relative"
            style="z-index: 2;"
          >
            <div class="mb-3">
              <h4 class="fw-bold mb-1 d-flex align-items-center">
                <.icon name="hero-map" class="w-6 h-6 text-primary me-2" />
                Live Logistics & Fulfillment Map
              </h4>
              <p class="text-muted small mb-0">
                Visualizing supply chains, replenishment routes, and stock levels.
              </p>
            </div>
            
    <!-- Visual Map Canvas -->
            <div
              class="flex-grow-1 w-100 my-3"
              style="position: relative; height: 260px; background: rgba(255, 255, 255, 0.02); border-radius: 12px; border: 1px solid rgba(255, 255, 255, 0.05); overflow: hidden;"
            >
              <!-- SVG Connection Lines -->
              <svg class="position-absolute w-100 h-100" style="top:0; left:0; pointer-events: none;">
                <!-- Dotted connection from Center (50%, 50%) to Store 1 (30%, 75%) -->
                <%= if Enum.at(@stores_data, 0) do %>
                  <line
                    x1="50%"
                    y1="50%"
                    x2="30%"
                    y2="75%"
                    stroke="#3b82f6"
                    stroke-width="2"
                    stroke-dasharray="6,4"
                    opacity="0.6"
                  />
                <% end %>
                <!-- Dotted connection from Center (50%, 50%) to Store 2 (75%, 30%) -->
                <%= if Enum.at(@stores_data, 1) do %>
                  <line
                    x1="50%"
                    y1="50%"
                    x2="75%"
                    y2="30%"
                    stroke="#10b981"
                    stroke-width="2"
                    stroke-dasharray="6,4"
                    opacity="0.6"
                  />
                <% end %>
              </svg>
              
    <!-- Central Warehouse Marker (Central Distribution Center) -->
              <%= for %{warehouse: w} <- @warehouses_data do %>
                <div
                  class="position-absolute translate-middle"
                  style="top: 50%; left: 50%; text-align: center; z-index: 10;"
                >
                  <!-- Pulse Ring -->
                  <span
                    class="position-absolute translate-middle start-50 top-50 spinner-grow text-primary opacity-25"
                    style="width: 50px; height: 50px; pointer-events: none;"
                  >
                  </span>
                  <!-- Pin -->
                  <div class="d-inline-flex flex-column align-items-center">
                    <div
                      class="badge bg-primary text-white p-2 rounded-circle shadow-sm border border-light d-flex align-items-center justify-content-center"
                      style="width: 44px; height: 44px;"
                    >
                      <.icon name="hero-archive-box" class="w-6 h-6" />
                    </div>
                    <% wh_total = Map.get(@warehouses_totals, w.id, 0) %>
                    <span class="badge bg-dark mt-1 text-white shadow-sm font-monospace border border-secondary">
                      {if wh_total >= 100, do: "100+", else: "#{wh_total}"}
                    </span>
                    <span class="small fw-bold text-white-50 mt-1 d-block">{w.name}</span>
                  </div>
                </div>
              <% end %>
              
    <!-- Store 1 Marker (First Store in List) -->
              <%= if store_data1 = Enum.at(@stores_data, 0) do %>
                <% %{store: s} = store_data1 %>
                <div
                  class="position-absolute translate-middle"
                  style="top: 75%; left: 30%; text-align: center; z-index: 10;"
                >
                  <!-- Pulse Ring -->
                  <% total = Map.get(@stores_totals, s.id, 0) %>
                  <% pulse_class =
                    if total < s.restock_threshold * 2, do: "text-warning", else: "text-success" %>
                  <span
                    class={[
                      "position-absolute translate-middle start-50 top-50 spinner-grow opacity-25",
                      pulse_class
                    ]}
                    style="width: 40px; height: 40px; pointer-events: none;"
                  >
                  </span>
                  <div class="d-inline-flex flex-column align-items-center">
                    <div
                      class={[
                        "badge text-white p-2 rounded-circle shadow-sm border border-light d-flex align-items-center justify-content-center",
                        if(total < 5, do: "bg-danger", else: "bg-success")
                      ]}
                      style="width: 38px; height: 38px;"
                    >
                      <.icon name="hero-building-storefront" class="w-5 h-5" />
                    </div>
                    <span class="badge bg-dark mt-1 text-white shadow-sm font-monospace border border-secondary">
                      {if total >= 100, do: "100+", else: "#{total}"}
                    </span>
                    <span class="small fw-bold text-white-50 mt-1 d-block">{s.name}</span>
                  </div>
                </div>
              <% end %>
              
    <!-- Store 2 Marker (Second Store in List) -->
              <%= if store_data2 = Enum.at(@stores_data, 1) do %>
                <% %{store: s} = store_data2 %>
                <div
                  class="position-absolute translate-middle"
                  style="top: 30%; left: 75%; text-align: center; z-index: 10;"
                >
                  <!-- Pulse Ring -->
                  <% total = Map.get(@stores_totals, s.id, 0) %>
                  <% pulse_class =
                    if total < s.restock_threshold * 2, do: "text-warning", else: "text-success" %>
                  <span
                    class={[
                      "position-absolute translate-middle start-50 top-50 spinner-grow opacity-25",
                      pulse_class
                    ]}
                    style="width: 40px; height: 40px; pointer-events: none;"
                  >
                  </span>
                  <div class="d-inline-flex flex-column align-items-center">
                    <div
                      class={[
                        "badge text-white p-2 rounded-circle shadow-sm border border-light d-flex align-items-center justify-content-center",
                        if(total < 5, do: "bg-danger", else: "bg-success")
                      ]}
                      style="width: 38px; height: 38px;"
                    >
                      <.icon name="hero-building-storefront" class="w-5 h-5" />
                    </div>
                    <span class="badge bg-dark mt-1 text-white shadow-sm font-monospace border border-secondary">
                      {if total >= 100, do: "100+", else: "#{total}"}
                    </span>
                    <span class="small fw-bold text-white-50 mt-1 d-block">{s.name}</span>
                  </div>
                </div>
              <% end %>
            </div>
            
    <!-- Legend -->
            <div class="d-flex justify-content-center gap-4 text-white-50 small flex-wrap">
              <span class="d-flex align-items-center">
                <span
                  class="badge bg-primary rounded-circle p-1 me-2"
                  style="width:10px; height:10px; display:inline-block;"
                >
                </span>
                Warehouse
              </span>
              <span class="d-flex align-items-center">
                <span
                  class="badge bg-success rounded-circle p-1 me-2"
                  style="width:10px; height:10px; display:inline-block;"
                >
                </span>
                Store (Healthy)
              </span>
              <span class="d-flex align-items-center">
                <span
                  class="badge bg-danger rounded-circle p-1 me-2"
                  style="width:10px; height:10px; display:inline-block;"
                >
                </span>
                Store (Low Stock / Empty)
              </span>
            </div>
          </div>
        </div>

        <div class="row g-4">
          <!-- Warehouses Inventory column -->
          <div class="col-lg-6">
            <div class="card border-0 shadow-sm p-4 h-100">
              <h3 class="fw-bold text-dark mb-3 d-flex align-items-center">
                <.icon name="hero-archive-box" class="w-6 h-6 text-primary me-2" />
                Warehouses (Wholesale)
              </h3>
              
    <!-- Product Highlight Selector (Square Buttons with Pictures) -->
              <div class="mb-4 bg-light p-3 rounded shadow-sm border border-light">
                <span class="text-muted small fw-bold d-block mb-2">Highlight Product Type:</span>
                <div class="d-flex align-items-center gap-3">
                  <!-- Laser Pointer Button -->
                  <button
                    phx-click="toggle_highlight"
                    phx-value-product-id={@pointer_id}
                    id="highlight-btn-pointer"
                    class={[
                      "btn p-0 border border-3 rounded-3 overflow-hidden shadow-sm transition-all",
                      if(@selected_product_id == @pointer_id,
                        do: "border-primary scale-105",
                        else: "border-light opacity-75 hover-opacity-100"
                      )
                    ]}
                    style="width: 60px; height: 60px;"
                    title="Super Laser Pointer"
                  >
                    <img
                      src={~p"/images/pointer.png"}
                      class="img-fluid w-100 h-100 object-fit-cover"
                      alt="Pointer"
                    />
                  </button>
                  
    <!-- Anti-Gravity Boots Button -->
                  <button
                    phx-click="toggle_highlight"
                    phx-value-product-id={@boots_id}
                    id="highlight-btn-boots"
                    class={[
                      "btn p-0 border border-3 rounded-3 overflow-hidden shadow-sm transition-all",
                      if(@selected_product_id == @boots_id,
                        do: "border-primary scale-105",
                        else: "border-light opacity-75 hover-opacity-100"
                      )
                    ]}
                    style="width: 60px; height: 60px;"
                    title="Anti-Gravity Boots"
                  >
                    <img
                      src={~p"/images/boots.png"}
                      class="img-fluid w-100 h-100 object-fit-cover"
                      alt="Boots"
                    />
                  </button>
                  
    <!-- Wormhole Generator Button -->
                  <button
                    phx-click="toggle_highlight"
                    phx-value-product-id={@generator_id}
                    id="highlight-btn-generator"
                    class={[
                      "btn p-0 border border-3 rounded-3 overflow-hidden shadow-sm transition-all",
                      if(@selected_product_id == @generator_id,
                        do: "border-primary scale-105",
                        else: "border-light opacity-75 hover-opacity-100"
                      )
                    ]}
                    style="width: 60px; height: 60px;"
                    title="Wormhole Generator"
                  >
                    <img
                      src={~p"/images/generator.png"}
                      class="img-fluid w-100 h-100 object-fit-cover"
                      alt="Generator"
                    />
                  </button>

                  <%= if @selected_product_id do %>
                    <button
                      phx-click="clear_highlight"
                      id="clear-highlight-btn"
                      class="btn btn-sm btn-outline-secondary ms-auto px-3"
                    >
                      Clear
                    </button>
                  <% end %>
                </div>
              </div>

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
                                <tr
                                  id={"wh-item-#{w.id}-#{item.product.id}"}
                                  class={[
                                    if(@selected_product_id == item.product.id,
                                      do: "table-warning fw-bold",
                                      else: ""
                                    )
                                  ]}
                                >
                                  <td class="ps-3 fw-bold text-dark d-flex align-items-center gap-2">
                                    <img
                                      src={~p"/images/#{product_image_name(item.product)}"}
                                      class="rounded border shadow-sm"
                                      style="width: 28px; height: 28px; object-fit: cover;"
                                      alt=""
                                    />
                                    <span>{item.product.name}</span>
                                  </td>
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
                              <th class="text-end">In Stock</th>
                              <th class="text-end pe-3">Actions</th>
                            </tr>
                          </thead>
                          <tbody>
                            <%= if items == [] do %>
                              <tr>
                                <td colspan="4" class="text-center py-4 text-muted small">
                                  No inventory recorded.
                                </td>
                              </tr>
                            <% else %>
                              <%= for item <- items do %>
                                <tr
                                  id={"store-item-#{s.id}-#{item.product.id}"}
                                  class={[
                                    if(@selected_product_id == item.product.id,
                                      do: "table-warning fw-bold",
                                      else: ""
                                    )
                                  ]}
                                >
                                  <td class="ps-3 fw-bold text-dark d-flex align-items-center gap-2">
                                    <img
                                      src={~p"/images/#{product_image_name(item.product)}"}
                                      class="rounded border shadow-sm"
                                      style="width: 28px; height: 28px; object-fit: cover;"
                                      alt=""
                                    />
                                    <span>{item.product.name}</span>
                                  </td>
                                  <td>
                                    <span class="badge bg-light text-secondary font-monospace">
                                      {item.product.sku}
                                    </span>
                                  </td>
                                  <td class="text-end fw-bold fs-6">
                                    <%= cond do %>
                                      <% item.quantity == 0 -> %>
                                        <span class="text-danger">0 (Out of stock)</span>
                                      <% item.quantity < s.restock_threshold -> %>
                                        <span class="text-warning">{item.quantity} (Low stock)</span>
                                      <% true -> %>
                                        <span class="text-success">{item.quantity}</span>
                                    <% end %>
                                  </td>
                                  <td class="text-end pe-3">
                                    <button
                                      phx-click="manual_restock"
                                      phx-value-store-id={s.id}
                                      phx-value-product-id={item.product.id}
                                      id={"restock-btn-#{s.id}-#{item.product.id}"}
                                      class="btn btn-sm btn-primary py-1 px-2 d-inline-flex align-items-center"
                                    >
                                      <.icon name="hero-arrow-path" class="w-3 h-3 me-1" />
                                      Restock (+10)
                                    </button>
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

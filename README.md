# 🚀 Enterprise Shop & Logistics Dashboard

A real-time enterprise e-commerce platform and inventory logistics tracking system built with Elixir, Phoenix, LiveView, Ecto, and Bootstrap.

---

## 📋 Overview

**Enterprise Shop** is a distributed retail and supply chain simulation application. It demonstrates modern Elixir/OTP patterns by connecting retail stores with central distribution warehouses. The application features a real-time storefront, cart checkout flow with database lock-based race condition prevention, and a visual logistics dashboard that tracks stock levels across the supply chain dynamically.

---

## ✨ Key Features

*   **Storefront Catalog (`/store`)**: A customer-facing portal where users can switch between different retail store locations, browse products, view real-time stock levels, and add items to their shopping cart.
*   **Interactive Shopping Cart (`/cart`)**: A seamless cart checkout interface. During checkout, stock is reserved using database locks. If any item goes out of stock or falls below a threshold, asynchronous replenishment routes are triggered.
*   **Warehouse Logistics Dashboard (`/warehouse/dashboard`)**: A premium internal tool showing:
    *   **Live Logistics & Fulfillment Map**: A dynamic visualization map using SVG connectors linking the Central Distribution Center with retail stores, showing real-time health indicator pulses (Healthy, Low Stock, or Out of Stock).
    *   **Interactive Highlights**: Clickable product thumbnail selectors allowing managers to highlight specific product types globally across all warehouse and store rows.
    *   **Manual Replenishment Actions**: One-click manual restock buttons to transfer inventory from warehouses to stores in real-time.
*   **Real-Time Synchronization**: Utilizes Phoenix PubSub to propagate inventory shifts globally across all open user sessions without manual page refreshes.

---

## 🏗️ Architecture & Design Principles

The application is structured using **Clean Domain-Driven Design (DDD)** concepts:

```
lib/enterprise_shop/
├── domain/            # Pure Business Entities (Cart, Store, Warehouse, Order, etc.)
├── schemas/           # Ecto Database Schemas & Migrations mapping to Postgres
├── use_cases/         # Transactional Interactors (Checkout, RestockStore)
├── inventory/         # OTP Warehouse GenServers & Supervisors
└── sales/             # In-memory Cart Registries
```

### 1. Pure Domain vs. Database Schemas
*   **Domain Entities** (`lib/enterprise_shop/domain/`): Pure structs containing core business calculations and validation logic (e.g. checking restocking thresholds, deducting/adding quantities). They have no dependency on Ecto or the database.
*   **Schemas** (`lib/enterprise_shop/schemas/`): Standard Ecto schemas representing database tables.

### 2. Transaction Serialisation (WarehouseServer)
To prevent race conditions when restocking a store from warehouse inventory:
*   Restocking actions run through a dedicated GenServer process (`EnterpriseShop.Inventory.WarehouseServer`).
*   Processes are spawned dynamically per warehouse on demand under `EnterpriseShop.WarehouseSupervisor` and registered in `EnterpriseShop.WarehouseRegistry` via a unique registry tuple.
*   Transactions employ Ecto database locks (`FOR UPDATE`) to serialize writes safely.

---

## 🛠️ OTP Supervision Tree

The application tree dynamically manages registries, supervisors, and agents:

1.  `EnterpriseShop.Repo` - Standard database connection wrapper.
2.  `EnterpriseShop.WarehouseRegistry` - Global registry routing calls dynamically to active `WarehouseServer` processes.
3.  `EnterpriseShop.WarehouseSupervisor` - A `DynamicSupervisor` managing warehouse server process lifecycles.
4.  `EnterpriseShop.Sales.CartRegistry` - An in-memory cache tracking active shopping carts across sessions.
5.  `EnterpriseShopWeb.Endpoint` - The Bandit web server handling HTTP requests and WebSocket connections.

---

## 🔌 API Endpoints

The system exposes REST endpoints for third-party logistics integrations:

| Method | Route | Description |
| :--- | :--- | :--- |
| `POST` | `/api/v1/warehouse/restock` | Replenishes store inventory from a specified warehouse. |

---

## 🚀 Getting Started

### Prerequisites

*   Elixir `~> 1.15`
*   Erlang `OTP 26`
*   PostgreSQL running locally

### Installation & Setup

1.  **Run setup alias** to download dependencies, migrate database, and seed initial stores and inventory:
    ```bash
    mix setup
    ```
2.  **Start Phoenix Endpoint**:
    ```bash
    mix phx.server
    # Or run inside IEx for debugging:
    iex -S mix phx.server
    ```
3.  Visit [`localhost:4000`](http://localhost:4000) from your browser.

### Quality Assurance & Linting

Before pushing your changes, always run the precommit pipeline:
```bash
mix precommit
```
This runs the formatter, compiles warnings as errors, unlocks unused dependencies, and runs all test suites.

### Testing

```bash
# Run all tests
mix test

# Run a specific test file
mix test test/enterprise_shop_web/live/warehouse_live_test.exs
```

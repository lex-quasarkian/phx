# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias EnterpriseShop.Repo
alias EnterpriseShop.Schemas.Enterprise
alias EnterpriseShop.Schemas.Warehouse
alias EnterpriseShop.Schemas.Store
alias EnterpriseShop.Schemas.Product
alias EnterpriseShop.Schemas.InventoryItem

# 1. Create Enterprise
enterprise = Repo.insert!(%Enterprise{name: "Antigravity Retail Group"})

# 2. Create Warehouse
warehouse =
  Repo.insert!(%Warehouse{name: "Central Distribution Center", enterprise_id: enterprise.id})

# 3. Create Stores
downtown_store =
  Repo.insert!(%Store{name: "Downtown Store", enterprise_id: enterprise.id, restock_threshold: 5})

uptown_store =
  Repo.insert!(%Store{name: "Uptown Store", enterprise_id: enterprise.id, restock_threshold: 5})

# 4. Create Products
laser =
  Repo.insert!(%Product{
    name: "Super Laser Pointer",
    sku: "LASER-001",
    price: Decimal.new("19.99")
  })

boots =
  Repo.insert!(%Product{
    name: "Anti-Gravity Boots",
    sku: "BOOTS-002",
    price: Decimal.new("249.99")
  })

wormhole =
  Repo.insert!(%Product{
    name: "Wormhole Generator",
    sku: "WORM-003",
    price: Decimal.new("999.00")
  })

# 5. Populate Warehouse Inventory
Repo.insert!(%InventoryItem{
  product_id: laser.id,
  location_type: "warehouse",
  location_id: warehouse.id,
  quantity: 150
})

Repo.insert!(%InventoryItem{
  product_id: boots.id,
  location_type: "warehouse",
  location_id: warehouse.id,
  quantity: 100
})

Repo.insert!(%InventoryItem{
  product_id: wormhole.id,
  location_type: "warehouse",
  location_id: warehouse.id,
  quantity: 50
})

# 6. Populate Store Inventory
# Downtown Store inventory: laser (10 - safe), boots (2 - low stock), wormhole (0 - out of stock)
Repo.insert!(%InventoryItem{
  product_id: laser.id,
  location_type: "store",
  location_id: downtown_store.id,
  quantity: 10
})

Repo.insert!(%InventoryItem{
  product_id: boots.id,
  location_type: "store",
  location_id: downtown_store.id,
  quantity: 2
})

Repo.insert!(%InventoryItem{
  product_id: wormhole.id,
  location_type: "store",
  location_id: downtown_store.id,
  quantity: 0
})

# Uptown Store inventory: laser (20 - safe), boots (8 - safe), wormhole (1 - low stock)
Repo.insert!(%InventoryItem{
  product_id: laser.id,
  location_type: "store",
  location_id: uptown_store.id,
  quantity: 20
})

Repo.insert!(%InventoryItem{
  product_id: boots.id,
  location_type: "store",
  location_id: uptown_store.id,
  quantity: 8
})

Repo.insert!(%InventoryItem{
  product_id: wormhole.id,
  location_type: "store",
  location_id: uptown_store.id,
  quantity: 1
})

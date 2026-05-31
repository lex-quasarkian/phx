defmodule EnterpriseShop.Repo.Migrations.CreateAll do
  use Ecto.Migration

  def change do
    create table(:enterprises) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:warehouses) do
      add :name, :string, null: false
      add :enterprise_id, references(:enterprises, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:stores) do
      add :name, :string, null: false
      add :enterprise_id, references(:enterprises, on_delete: :delete_all), null: false
      add :restock_threshold, :integer, default: 5, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:products) do
      add :name, :string, null: false
      add :sku, :string, null: false
      add :price, :decimal, precision: 10, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:products, [:sku])

    create table(:inventory_items) do
      add :product_id, references(:products, on_delete: :delete_all), null: false
      # "warehouse" or "store"
      add :location_type, :string, null: false
      # references warehouse or store ID
      add :location_id, :integer, null: false
      add :quantity, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:inventory_items, [:product_id, :location_type, :location_id])

    create table(:orders) do
      add :store_id, references(:stores, on_delete: :delete_all), null: false
      # e.g. "new", "registered", "granted", etc.
      add :state, :string, null: false
      add :total_price, :decimal, precision: 10, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:order_lines) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :quantity, :integer, null: false
      add :price, :decimal, precision: 10, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:order_lines, [:order_id, :product_id])
  end
end

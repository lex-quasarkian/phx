defmodule EnterpriseShop.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EnterpriseShopWeb.Telemetry,
      EnterpriseShop.Repo,
      {DNSCluster, query: Application.get_env(:enterprise_shop, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EnterpriseShop.PubSub},
      # Registry for locating Warehouse GenServer processes
      {Registry, keys: :unique, name: EnterpriseShop.WarehouseRegistry},
      # DynamicSupervisor to spin up Warehouse GenServers on demand
      {DynamicSupervisor, name: EnterpriseShop.WarehouseSupervisor, strategy: :one_for_one},
      # In-memory CartRegistry to track active customer carts
      {EnterpriseShop.Sales.CartRegistry, name: EnterpriseShop.Sales.CartRegistry},
      # Start to serve requests, typically the last entry
      EnterpriseShopWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EnterpriseShop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EnterpriseShopWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

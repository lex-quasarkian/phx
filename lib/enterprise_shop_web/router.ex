defmodule EnterpriseShopWeb.Router do
  use EnterpriseShopWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug EnterpriseShopWeb.Plugs.EnsureSessionId
    plug :fetch_live_flash
    plug :put_root_layout, html: {EnterpriseShopWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EnterpriseShopWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/store", StoreLive.Index, :index
    live "/cart", CartLive.Show, :show
    live "/warehouse/dashboard", WarehouseLive.Dashboard, :index
  end

  scope "/api/v1", EnterpriseShopWeb do
    pipe_through :api

    post "/warehouse/restock", API.WarehouseController, :restock
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:enterprise_shop, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EnterpriseShopWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

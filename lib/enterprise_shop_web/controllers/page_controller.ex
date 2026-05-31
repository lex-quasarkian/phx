defmodule EnterpriseShopWeb.PageController do
  use EnterpriseShopWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

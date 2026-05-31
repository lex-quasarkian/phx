defmodule EnterpriseShopWeb.Plugs.EnsureSessionId do
  @moduledoc """
  Plug to ensure that every session has a unique session_id.
  Used to identify shopping carts.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :session_id) do
      conn
    else
      session_id = :crypto.strong_rand_bytes(16) |> Base.encode16()
      put_session(conn, :session_id, session_id)
    end
  end
end

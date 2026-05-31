defmodule EnterpriseShop.HTTPClient.ReqImpl do
  @moduledoc """
  Real implementation of the HTTPClient behavior using the Req library.
  """
  @behaviour EnterpriseShop.HTTPClient

  @impl true
  def post(url, body) do
    case Req.post(url, json: body, retry: false) do
      {:ok, %Req.Response{status: 200} = resp} -> {:ok, resp}
      {:ok, resp} -> {:error, resp}
      {:error, reason} -> {:error, reason}
    end
  end
end

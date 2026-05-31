defmodule EnterpriseShop.HTTPClient do
  @moduledoc """
  Behavior defining HTTP client requests.
  Used to abstract out HTTP calls for mockability in tests.
  """

  @callback post(String.t(), map()) :: {:ok, any()} | {:error, any()}
end

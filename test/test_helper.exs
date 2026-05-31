ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(EnterpriseShop.Repo, :manual)

# Define mock for testing HTTP requests
Mox.defmock(EnterpriseShop.HTTPClientMock, for: EnterpriseShop.HTTPClient)

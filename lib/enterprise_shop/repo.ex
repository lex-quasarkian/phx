defmodule EnterpriseShop.Repo do
  use Ecto.Repo,
    otp_app: :enterprise_shop,
    adapter: Ecto.Adapters.Postgres
end

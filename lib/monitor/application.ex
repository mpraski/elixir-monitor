defmodule Monitor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    store = Application.get_env(:monitor, :initial_store)
    urls = get_urls()

    children = [
      {Registry, [keys: :unique, name: :url_registry]},
      {Monitor.Store, store},
      {Monitor.CoordinatorSupervisor, urls},
      :hackney_pool.child_spec(:lookup_pool, timeout: 10_000)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Monitor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_urls do
    case Application.get_env(:monitor, :initial_urls) do
      {:ok, %{"urls" => urls}} -> urls
      _ -> Process.exit(self(), "Could not load URLs")
    end
  end
end

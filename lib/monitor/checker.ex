defmodule Monitor.Checker do
  use GenServer

  def start_link(url) do
    GenServer.start_link(__MODULE__, url, name: via_tuple(url))
  end

  def init(url) do
    schedule_check()
    {:ok, url}
  end

  def handle_info(:check_status, url) do
    spawn_link(fn -> do_request(url) end)
    schedule_check()

    {:noreply, url}
  end

  def handle_cast(:stop, url) do
    cleanup(url)
    {:stop, "URL deleted", url}
  end

  def kill_yourself(url) do
    with {pid, _} <- Registry.lookup(:url_registry, url) do
      GenServer.cast(pid, :stop)
    end
  end

  defp schedule_check() do
    Process.send_after(self(), :check_status, 1_000)
  end

  defp do_request(url) do
    case HTTPoison.get(url, [], hackney: [pool: :lookup_pool]) do
      {:ok, %HTTPoison.Response{status_code: code}} ->
        save_ok(url, code)

      {:error, %HTTPoison.Error{reason: reason}} ->
        save_error(url, reason)
    end
  end

  defp save_ok(url, code) do
    Monitor.Store.put(url, %Monitor.Result{
      status: code,
      last_checked: DateTime.utc_now()
    })
  end

  defp save_error(url, error) do
    Monitor.Store.put(url, %Monitor.Result{
      error: error,
      last_checked: DateTime.utc_now()
    })
  end

  defp cleanup(url) do
    Registry.unregister(:url_registry, url)
    Monitor.Store.delete(url)
  end

  defp via_tuple(url) do
    {:via, Registry, {:url_registry, url}}
  end
end

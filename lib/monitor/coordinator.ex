defmodule Monitor.Coordinator do
  use GenServer

  @frequency 1_000
  @timeout 5_000

  def start_link({_table, _list} = state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init({_table, _list} = state) do
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, {table, list} = state) do
    :ok = check_urls(table, list)
    schedule_work()

    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, @frequency)
  end

  defp check_urls(table, list) do
    list
    |> Enum.map(&request_check/1)
    |> Enum.map(&Task.await(&1, @timeout))
    |> Enum.each(&save_result(table, &1))
  end

  defp request_check(url) do
    Task.async(fn ->
      :poolboy.transaction(
        :checker,
        fn pid ->
          Monitor.Checker.check_url(pid, url)
        end,
        @timeout
      )
    end)
  end

  defp save_result(table, result) do
    Task.start_link(fn ->
      {url, entry} =
        case result do
          {:ok, {url, code}} ->
            {url, %Monitor.Result{status: code}}

          {:error, {url, reason}} ->
            {url, %Monitor.Result{error: reason}}
        end

      :ets.insert(table, {url, %{entry | last_checked: DateTime.utc_now()}})
    end)
  end
end

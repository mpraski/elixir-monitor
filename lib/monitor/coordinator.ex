defmodule Monitor.Coordinator do
  use Task

  def start_link(list) do
    Task.start_link(__MODULE__, :run, [list])
  end

  def run(list) do
    receive do
    after
      1_000 ->
        process(list)
        run(list)
    end
  end

  defp process(list) do
    list
    |> Enum.map(&start_checker/1)
    |> Enum.map(&receive_result/1)
  end

  defp start_checker(url) do
    Monitor.Checker.start_link({self(), url})
  end

  defp receive_result(pid) do
    receive do
      {^pid, {:ok, url, status}} ->
        save_result(url, status)

      {^pid, {:error, url, message}} ->
        notify_error(url, message)
    end
  end

  defp save_result(url, status) do
    Monitor.Store.put(url, %Monitor.Result{
      status: status,
      last_checked: DateTime.utc_now()
    })
  end

  defp notify_error(url, error) do
    Monitor.Store.put(url, %Monitor.Result{
      error: error,
      last_checked: DateTime.utc_now()
    })
  end
end

defmodule Monitor.Coordinator do
  use GenServer

  def start_link(list) do
    GenServer.start_link(__MODULE__, list, name: __MODULE__)
  end

  def init(list) do
    start_workers(list)
    {:ok, list}
  end

  def add_url(url) do
    GenServer.cast(__MODULE__, {:add_url, url})
  end

  def delete_url(url) do
    GenServer.cast(__MODULE__, {:delete_url, url})
  end

  def handle_cast({:add_url, url}, list) do
    Monitor.Checker.start_link(url)
    {:noreply, [url | list]}
  end

  def handle_cast({:delete_url, url}, list) do
    Monitor.Checker.kill_yourself(url)
    {:noreply, list -- [url]}
  end

  defp start_workers(list) do
    list |> Enum.each(&Monitor.Checker.start_link/1)
  end
end

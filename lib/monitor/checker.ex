defmodule Monitor.Checker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:check_url, url}, _from, state) do
    case HTTPoison.get(url, [], hackney: [pool: :lookup_pool]) do
      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:reply, {:ok, {url, code}}, state}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:reply, {:error, {url, reason}}, state}
    end
  end

  def check_url(pid, url) do
    GenServer.call(pid, {:check_url, url})
  end
end

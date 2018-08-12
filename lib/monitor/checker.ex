defmodule Monitor.Checker do
  use Task

  def start_link({parent, url}) do
    {:ok, pid} = Task.start_link(__MODULE__, :check, [{parent, url}])
    pid
  end

  def check({parent, url}) do
    case HTTPoison.get(url, [], hackney: [pool: :lookup_pool]) do
      {:ok, %HTTPoison.Response{status_code: code}} ->
        send(parent, {self(), {:ok, url, code}})

      {:error, %HTTPoison.Error{reason: reason}} ->
        send(parent, {self(), {:error, url, reason}})
    end
  end
end

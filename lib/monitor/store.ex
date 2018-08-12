defmodule Monitor.Store do
  use GenServer

  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(initial_state) do
    {:ok, initial_state}
  end

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  def put(key, record) do
    GenServer.cast(__MODULE__, {:put, key, record})
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:put, key, record}, state) do
    {:noreply, Map.put(state, key, record)}
  end
end

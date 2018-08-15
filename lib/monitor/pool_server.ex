defmodule Monitor.PoolServer do
  use GenServer

  defmodule State do
    defstruct sup: nil, size: nil, worker_sup: nil, workers: nil, monitors: nil
  end

  def start_link([sup, config]) do
    GenServer.start_link(__MODULE__, [sup, config], name: __MODULE__)
  end

  def init([sup, config]) when is_pid(sup) do
    monitors = :ets.new(:monitors, [:private])
    init(config, %State{sup: sup, monitors: monitors})
  end

  def init([{:size, size} | rest], state) do
    init(rest, %{state | size: size})
  end

  def init([_ | rest], state) do
    init(rest, state)
  end

  def init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  def checkout do
    GenServer.call(__MODULE__, :checkout)
  end

  def checkin(worker) do
    GenServer.cast(__MODULE__, {:checkin, worker})
  end

  def handle_info(:start_worker_supervisor, %{sup: sup, size: size} = state) do
    {:ok, worker_sup} = Supervisor.start_child(sup, Monitor.WorkerSupervisor)

    workers = prepopulate(size, worker_sup)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  def handle_call(:checkout, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_cast({:checkin, worker}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [pid | workers]}}

      [] ->
        {:noreply, state}
    end
  end

  defp prepopulate(size, sup) do
    prepopulate(size, sup, [])
  end

  defp prepopulate(size, _sup, workers) when size < 1 do
    workers
  end

  defp prepopulate(size, sup, workers) do
    prepopulate(size - 1, sup, [new_worker(sup) | workers])
  end

  defp new_worker(sup) do
    {:ok, worker} = DynamicSupervisor.start_child(sup, {Monitor.Worker, []})
    worker
  end
end

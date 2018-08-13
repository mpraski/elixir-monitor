defmodule Monitor.CoordinatorSupervisor do
    use Supervisor
  
    def start_link(urls) do
      Supervisor.start_link(__MODULE__, urls)
    end
  
    def init(urls) do
      children = [
        {Monitor.Coordinator, urls},
      ]
  
      Supervisor.init(children, strategy: :one_for_one)
    end
  end
  
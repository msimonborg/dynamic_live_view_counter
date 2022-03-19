defmodule LiveViewCounter.Count.Supervisor do
  use DynamicSupervisor

  alias LiveViewCounter.Count

  @name __MODULE__

  # ---- Client API ----

  def start_link(init_arg) do
    DynamicSupervisor.start_link(@name, init_arg, name: @name)
  end

  def new_count(topic) do
    DynamicSupervisor.start_child(@name, {Count, topic})
  end

  def stop_count(topic) do
    DynamicSupervisor.terminate_child(@name, Count.whereis(topic))
  end

  # ---- Server Callbacks ----

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

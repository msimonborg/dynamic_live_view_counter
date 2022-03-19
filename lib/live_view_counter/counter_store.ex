defmodule LiveViewCounter.CounterStore do
  use GenServer

  alias LiveViewCounter.Count.Supervisor, as: CountSup
  alias Phoenix.PubSub

  @name __MODULE__
  @pubsub LiveViewCounter.PubSub
  @topic "counter_index"

  # ---- Client API ----

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: @name)
  end

  def add do
    GenServer.call(@name, :add)
  end

  def remove(counter) do
    GenServer.call(@name, {:remove, counter})
  end

  def list do
    GenServer.call(@name, :list)
  end

  def pubsub_service, do: @pubsub
  def topic, do: @topic

  # ---- Server Callbacks ----

  @impl true
  def init(_init_arg) do
    {:ok, %{new_counter_id: 1, counters: []}}
  end

  @impl true
  def handle_call(:list, _from, %{counters: counters} = state) do
    {:reply, counters, state}
  end

  def handle_call(:add, _from, %{new_counter_id: id, counters: counters} = _state) do
    topic = LiveViewCounterWeb.Counter.topic(id)
    CountSup.new_count(topic)
    new_counters = [topic | counters]
    broadcast(new_counters)
    {:reply, :ok, %{new_counter_id: id + 1, counters: new_counters}}
  end

  def handle_call({:remove, topic}, _from, %{counters: counters} = state) do
    CountSup.stop_count(topic)
    new_counters = List.delete(counters, topic)
    broadcast({topic, :removed})
    broadcast(new_counters)
    {:reply, :ok, %{state | counters: new_counters}}
  end

  defp broadcast({topic, :removed}) do
    PubSub.broadcast(@pubsub, topic, :removed)
  end

  defp broadcast(counters) when is_list(counters) do
    PubSub.broadcast(@pubsub, @topic, {:new_state, counters})
  end
end

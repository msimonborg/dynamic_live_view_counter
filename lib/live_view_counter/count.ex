defmodule LiveViewCounter.Count do
  use GenServer

  alias Phoenix.PubSub

  @pubsub LiveViewCounter.PubSub
  @registry LiveViewCounter.Registry

  # -------  External API (runs in client process) -------

  def start_link(topic) do
    GenServer.start_link(__MODULE__, topic, name: via_name(topic))
  end

  def incr(topic) do
    GenServer.call(via_name(topic), :incr)
  end

  def decr(topic) do
    GenServer.call(via_name(topic), :decr)
  end

  def current(topic) do
    GenServer.call(via_name(topic), :current)
  end

  def pubsub_service, do: @pubsub
  def via_name(topic), do: {:via, Registry, {@registry, topic}}

  def whereis(topic) do
    case Registry.lookup(@registry, topic) do
      [{pid, nil}] -> pid
      [] -> nil
    end
  end

  # -------  Implementation  (Runs in GenServer process) -------

  @impl true
  def init(topic) do
    {:ok, {topic, 0}}
  end

  @impl true
  def handle_call(:current, _from, {_topic, count} = state) do
    {:reply, count, state}
  end

  def handle_call(:topic, _from, {topic, _count} = state) do
    {:reply, topic, state}
  end

  @impl true
  def handle_call(:incr, _from, state) do
    make_change(state, +1)
  end

  def handle_call(:decr, _from, state) do
    make_change(state, -1)
  end

  defp make_change({topic, count} = _state, change) do
    new_count = count + change
    PubSub.broadcast(@pubsub, topic, {:count, new_count})
    {:reply, new_count, {topic, new_count}}
  end
end

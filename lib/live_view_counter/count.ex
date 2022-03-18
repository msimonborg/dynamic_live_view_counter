defmodule LiveViewCounter.Count do
  use GenServer

  alias Phoenix.PubSub

  @name :count_server
  @pubsub LiveViewCounter.PubSub
  @start_value 0

  # -------  External API (runs in client process) -------

  def topic do
    "count"
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, @start_value, name: @name)
  end

  def incr() do
    GenServer.call(@name, :incr)
  end

  def decr() do
    GenServer.call(@name, :decr)
  end

  def current() do
    GenServer.call(@name, :current)
  end

  # -------  Implementation  (Runs in GenServer process) -------

  def init(start_count) do
    {:ok, start_count}
  end

  def handle_call(:current, _from, count) do
    {:reply, count, count}
  end

  def handle_call(:incr, _from, count) do
    make_change(count, +1)
  end

  def handle_call(:decr, _from, count) do
    make_change(count, -1)
  end

  defp make_change(count, change) do
    new_count = count + change
    PubSub.broadcast(@pubsub, topic(), {:count, new_count})
    {:reply, new_count, new_count}
  end
end

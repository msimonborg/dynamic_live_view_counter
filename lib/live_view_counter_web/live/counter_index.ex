defmodule LiveViewCounterWeb.CounterIndex do
  use Phoenix.LiveView

  alias LiveViewCounter.CounterStore
  alias Phoenix.PubSub

  @pubsub CounterStore.pubsub_service()
  @topic CounterStore.topic()

  def render(assigns) do
    ~H"""
    <div>
      <button phx-click="add">Add New</button>
      <ul>
        <%= for counter <- @counters do %>
          <li><a href={counter}><%= format(counter) %></a> - <a href="#" phx-click={"remove:#{counter}"}>delete</a></li>
        <% end %>
      </ul>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    PubSub.subscribe(@pubsub, @topic)
    {:ok, assign(socket, :counters, CounterStore.list())}
  end

  def handle_event("add", _, socket) do
    CounterStore.add()
    {:noreply, socket}
  end

  def handle_event("remove:" <> counter, _, socket) do
    CounterStore.remove(counter)
    {:noreply, socket}
  end

  def handle_info({:new_state, counters}, socket) do
    {:noreply, assign(socket, :counters, counters)}
  end

  defp format(counter) do
    counter
    |> String.split("/")
    |> Enum.join(" ")
  end
end

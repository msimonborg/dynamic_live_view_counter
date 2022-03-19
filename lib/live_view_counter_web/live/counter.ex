defmodule LiveViewCounterWeb.Counter do
  use Phoenix.LiveView

  alias LiveViewCounter.{Count, Presence}
  alias Phoenix.PubSub

  @pubsub Count.pubsub_service()

  def topic(id), do: "counter/#{id}"
  def presence_topic(id), do: "presence:#{topic(id)}"

  def render(assigns) do
    ~H"""
    <div>
      <h1>Counter <%= @id %></h1>
      <h1>The count is: <%= @val %></h1>
      <button phx-click="dec">-</button>
      <button phx-click="inc">+</button>
      <h1>Current users: <%= @present %></h1>
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    topic = topic(id)

    case Count.whereis(topic) do
      nil ->
        {:ok, push_redirect(socket, to: "/")}

      _ ->
        presence_topic = presence_topic(id)
        PubSub.subscribe(@pubsub, topic)
        Presence.track(self(), presence_topic, socket.id, %{})
        LiveViewCounterWeb.Endpoint.subscribe(presence_topic)

        initial_present =
          Presence.list(presence_topic)
          |> map_size()

        {:ok, assign(socket, val: Count.current(topic), present: initial_present, id: id)}
    end
  end

  def handle_event("inc", _, socket) do
    topic = socket.assigns.id |> topic()
    {:noreply, assign(socket, :val, Count.incr(topic))}
  end

  def handle_event("dec", _, socket) do
    topic = socket.assigns.id |> topic()
    {:noreply, assign(socket, :val, Count.decr(topic))}
  end

  def handle_info({:count, count}, socket) do
    {:noreply, assign(socket, :val, count)}
  end

  def handle_info(:removed, socket) do
    {:noreply, push_redirect(socket, to: "/")}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{present: present}} = socket
      ) do
    new_present = present + map_size(joins) - map_size(leaves)
    {:noreply, assign(socket, :present, new_present)}
  end
end

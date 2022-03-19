defmodule LiveViewCounter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LiveViewCounterWeb.Telemetry,
      {Phoenix.PubSub, name: LiveViewCounter.PubSub},
      {Registry, keys: :unique, name: LiveViewCounter.Registry},
      LiveViewCounter.Count.Supervisor,
      LiveViewCounter.CounterStore,
      LiveViewCounter.Presence,
      LiveViewCounterWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveViewCounter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveViewCounterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

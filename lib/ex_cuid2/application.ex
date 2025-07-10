defmodule ExCuid2.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExCuid2
    ]

    opts = [strategy: :one_for_one, name: ExCuid2.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

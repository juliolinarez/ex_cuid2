if Code.ensure_loaded?(Ecto.Type) do
  defmodule ExCuid2.Ecto.Type do
    @moduledoc """
    Ecto type for CUID2 values.

    To use this, add the following to your `config.exs`:

        config :my_app, MyApp.Repo,
          ecto_types: [cuid2: ExCuid2.Ecto.Type]
    """
    use Ecto.Type

    def type, do: :cuid2

    def cast(cuid) when is_binary(cuid) do
      if ExCuid2.is_valid?(cuid) do
        {:ok, cuid}
      else
        :error
      end
    end

    def cast(_), do: :error

    def load(data), do: {:ok, data}
    def dump(data), do: {:ok, data}

    def autogenerate() do
      ExCuid2.generate()
    end
  end
end

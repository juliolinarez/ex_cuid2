if Code.ensure_loaded?(Ecto.Type) do
  defmodule ExCuid2.Ecto.Type do
    @moduledoc """
    Ecto type for CUID2 values.

    This allows you to use `:cuid2` as a custom type in your Ecto schemas.

    ## Usage

    Add the following to your `config.exs` to register the type:

        config :my_app, MyApp.Repo,
          ecto_types: [cuid2: ExCuid2.Ecto.Type]

    Then in your schema:

        field :id, :cuid2, autogenerate: true
    """
    use Ecto.Type

    # The underlying database type
    def type, do: :cuid2

    # Cast input into the expected type.
    # Accepts only valid CUID strings.
    def cast(cuid) when is_binary(cuid) do
      if ExCuid2.is_valid?(cuid) do
        {:ok, cuid}
      else
        :error
      end
    end

    # Reject anything that isn't a binary
    def cast(_), do: :error

    # Load data from the database (as-is)
    def load(data), do: {:ok, data}

    # Prepare data to be inserted into the database (as-is)
    def dump(data), do: {:ok, data}

    # Automatically generate a new CUID if the field has `autogenerate: true`
    def autogenerate(length \\ 24) do
      ExCuid2.generate(length)
    end
  end
end


# ExCuid2

[![Hex.pm](https://img.shields.io/hexpm/v/ex_cuid2.svg)](https://hex.pm/packages/ex_cuid2)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_cuid2/)

`ExCuid2` is a robust, thread-safe, and testable CUID2 (Collision-Resistant Unique Identifiers) generator for Elixir.

This implementation follows the CUID2 standard and generates safe, horizontally scalable IDs,
ideal for use as primary keys in databases.

Features:
- Prefix with a random letter.
- Timestamp in milliseconds.
- Local Atomic counter to prevent collisions in the same millisecond.
- Cryptographically secure entropy.
- Process fingerprint to ensure uniqueness across nodes.
## Installation

The package is available in [Hex](https://hex.pm/packages/ex_cuid2) and can be installed by adding `ex_cuid2` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_cuid2, "~> 0.10.1"}
  ]
end
```

## Usage

### Generating IDs

You can generate a CUID2 with the default length (24) or specify a custom length.

```elixir
# Generate a default CUID2
iex> ExCuid2.generate()
"v8p7k3f9z1m0c2x4b6n5j7h8"

# Generate a CUID2 with a custom length (e.g., 30)
iex> ExCuid2.generate(30)
"b5n6m4j3h2g1f0d9s8a7q6w5e4r3t2"
```

### Validating a CUID2

You can check if a given string conforms to the CUID2 format using `is_valid?/1`. It performs a check based on length and character set and returns `false` for any non-binary input without raising an error.

```elixir
iex> id = ExCuid2.generate()
"t9p7k3f9z1m0c2x4b6n5j7h8"

iex> ExCuid2.is_valid?(id)
true

# --- Invalid Cases ---

# Too short
iex> ExCuid2.is_valid?("a123")
false

# Starts with a number
iex> ExCuid2.is_valid?("1abcdefghijklmnopqrstuvw")
false

# Contains invalid characters (uppercase)
iex> ExCuid2.is_valid?("aBcdefghijklmnopqrstuvwX")
false

# Wrong data type
iex> ExCuid2.is_valid?(12345)
false
```

## Ecto Integration

`ExCuid2` provides an optional `Ecto.Type` module for seamless integration with your Ecto schemas.

### 1. Configure Your Repo

First, register `ExCuid2.Ecto.Type` as a custom type in your application's configuration (`config/config.exs`).

```elixir
# in config/config.exs
config :my_app, MyApp.Repo,
  ecto_types: [cuid2: ExCuid2.Ecto.Type]
```
*(Replace `:my_app` and `MyApp.Repo` with your application's name and Repo module.)*

### 2. Use in Your Schema

It's recommended to use it for your primary key with `autogenerate: true` and to set the `@foreign_key_type`.

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  # Define the primary key as a CUID2
  @primary_key {:id, ExCuid2.Ecto.Type, autogenerate: true}
  @foreign_key_type ExCuid2.Ecto.Type
  schema "users" do
    field :name, :string
    field :email, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
  end
end
```
You could use this : `@primary_key {:id, ExCuid2.Ecto.Type, autogenerate: 32}` if you use a cuid2 longer.


With this setup, Ecto will automatically generate a new CUID2 for the `:id` field whenever you insert a new record, giving you secure and scalable primary keys out of the box.

```elixir
defmodule MyApp.Accounts.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    # primary_key: false is not needed here since we are defining a custom primary key
    create table(:record, primary_key: false) do
      # we use char beacuse cuid2 has a fixed length.
      add :id, :char, primary_key: true, size: 24 # check the cuid2 length
      add :title, :string
      add :body, :string

      timestamps(type: :utc_datetime)
    end
    
    # Use a hash index for random values as cuid2.
    create index(:record, [:id], using: :hash)
  end
end

```

### Optional Custom Postgres Domain

``` elixir
  defmodule MyApp.Repo.Migrations.CreateCuid2DomainType do
    use Ecto.Migration
    # Create a custom domain type for cuid2
    # This is a PostgreSQL specific feature, so ensure your database supports it.
    # The cuid2 format is a 24-32 character string starting with a letter followed by lowercase alphanumeric characters.
    # The regex checks that the value starts with a letter and is followed by 23 lowercase alphanumeric characters.
    # Adjust the regex as necessary to fit your specific requirements.
    # Note: The size of 24 is based on the standard CUID2 length.
    # If you are using a different length, adjust the size accordingly.
    def up do
      execute("""
      CREATE DOMAIN cuid2 AS character(24)
        CONSTRAINT cuid2_check CHECK (VALUE ~ '^[a-z][a-z0-9]{23}$');
      """)
    end

    def down do
      execute("DROP DOMAIN cuid2;")
    end
  end
```

After this migration you can use this :

```elixir
defmodule MyApp.Repo.Migrations.CreateRecord do
  use Ecto.Migration

  def change do
    create table(:record, primary_key: false) do
      # add :id, :char, primary_key: true, size: 24
      add :id, :cuid2, primary_key: true
      add :title, :string
      add :body, :string

      timestamps(type: :utc_datetime)
    end

    # Use a hash index for random values as cuid2.
    create index(:record, [:id], using: :hash)
  end
end

```


defmodule ExCuid2 do
  @moduledoc """
  CUID2 (Collision-Resistant Unique Identifiers) generator in Elixir.

  This implementation follows the CUID2 standard and generates safe, horizontally scalable IDs,
  ideal for use as primary keys in databases.

  Features:
  - Prefix with a random letter.
  - Timestamp in milliseconds.
  - Atomic counter to prevent collisions in the same millisecond.
  - Cryptographically secure entropy.
  - Process fingerprint to ensure uniqueness across nodes.
  """

  # The agent safely maintains the counter state between processes.
  # The name :cuid2_counter is a convention to register it globally in the node.
  @counter_agent :cuid2_counter

  # Use the ~c sigil for charlists to avoid deprecation warnings.
  @base36_chars ~c"0123456789abcdefghijklmnopqrstuvwxyz"

  @doc """
  Defines how this module should be supervised.
  This allows it to be added directly to a supervision tree.
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 1000
    }
  end

  @doc """
  Starts the counter agent.

  It should be added to the supervision tree in `application.ex`.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> 0 end, name: @counter_agent)
  end

  @doc """
  Generates a CUID2 with the default length (24 characters).

  ## Examples
      iex> ExCuid2.generate() |> String.length()
      24
  """
  def generate(), do: generate(24)

  @doc """
  Generates a CUID2 with a specific length (between 24 and 32).

  ## Examples
      iex> ExCuid2.generate(32) |> String.length()
      32
  """
  def generate(length) when is_integer(length) and length in 24..32 do
    # 1. Get ID components
    timestamp = System.system_time(:millisecond)
    counter = get_and_increment_counter()
    entropy = :crypto.strong_rand_bytes(length) # Use crypto for security
    fingerprint = create_fingerprint()

    # 2. Combine everything into a single hash to mix entropy
    combined_hash =
      :crypto.hash(
        :sha256,
        [
          Integer.to_string(timestamp),
          Integer.to_string(counter),
          entropy,
          fingerprint
        ]
      )

    # 3. Convert the hash to a large number and encode it in Base36
    hash_integer = :binary.decode_unsigned(combined_hash)
    base36_encoded = to_base36(hash_integer)

    # 4. Add a random letter prefix and adjust length
    # Use ~c sigil here as well.
    prefix = <<Enum.random(~c"abcdefghijklmnopqrstuvwxyz")>>
    # Take a portion from the end to ensure maximum randomness
    body = String.slice(base36_encoded, -(length - 1), length - 1)

    prefix <> body
  end

  @doc """
  Validates whether a string matches the CUID2 format.

  ## Examples
      iex> ExCuid2.is_valid?("t4p35j2w2fiyqrec00pjxd7b")
      true

      iex> ExCuid2.is_valid?("123-abc")
      false
  """
  def is_valid?(cuid) do
    # Regex to validate standard format
    is_binary(cuid) and Regex.match?(~r/^[a-z][a-z0-9]{23,31}$/, cuid)
  end

  # --- Private functions ---

  # Atomically gets and increments the counter using the Agent.
  defp get_and_increment_counter do
    Agent.get_and_update(@counter_agent, fn state ->
      # Arbitrarily high limit to reset the counter and prevent indefinite growth
      next_state = if state > 1_000_000, do: 0, else: state + 1
      {state, next_state}
    end)
  end

  # Creates a process fingerprint to add more entropy
  # between different machines or application restarts.
  defp create_fingerprint do
    pid_string = :erlang.pid_to_list(self()) |> to_string()
    node_string = Atom.to_string(Node.self())

    :crypto.hash(:sha256, pid_string <> node_string)
  end

  # Converts an integer to a Base36 string
  defp to_base36(number) do
    base = 36

    Stream.unfold(number, fn
      0 -> nil
      n -> {rem(n, base), div(n, base)}
    end)
    |> Enum.map(&Enum.at(@base36_chars, &1))
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end
end

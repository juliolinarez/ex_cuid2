defmodule ExCuid2 do
  @moduledoc """
  A robust, thread-safe, and testable CUID2 (Collision-Resistant Unique Identifiers) generator for Elixir.

  This implementation follows the CUID2 standard and generates safe, horizontally scalable IDs,
  ideal for use as primary keys in databases.

  Features:
  - Prefix with a random letter.
  - Timestamp in milliseconds.
  - Atomic counter to prevent collisions in the same millisecond.
  - Cryptographically secure entropy.
  - Process fingerprint to ensure uniqueness across nodes.
  """

  # --- Module Attributes ---

  @default_counter_name :cuid2_counter
  @default_length 24
  @base36_chars ~c"0123456789abcdefghijklmnopqrstuvwxyz"
  @cuid2_prefix ~c"abcdefghijklmnopqrstuvwxyz"
  @cuid2_base 36

  # --- OTP Behaviours (for supervision) ---

  @doc """
  Defines how this module should be supervised.
  This allows it to be added directly to a supervision tree in `application.ex`.
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
  It can be started with a custom name, which is useful for testing.
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, @default_counter_name)
    Agent.start_link(fn -> 0 end, name: name)
  end

  # --- Public API ---

  @doc """
  Generates a CUID2 with the default length and counter.
  """
  def generate(), do: generate(@default_length, @default_counter_name)

  @doc """
  Generates a CUID2 with a specific length, using the default counter.
  Raises `FunctionClauseError` if length is not an integer.
  """
  def generate(length) when is_integer(length), do: generate(length, @default_counter_name)

  @doc """
  Generates a CUID2 with a specific length and counter reference.

  This is the core function. It raises a `FunctionClauseError` if arguments
  are invalid (e.g., length is not an integer between 24-32, or counter_name
  is not an atom or PID).
  """
  def generate(length, counter_name)
      when is_integer(length) and
             length in 24..32 and
             (is_atom(counter_name) or is_pid(counter_name)) do
    # 1. Get ID components
    timestamp = System.system_time(:millisecond)
    counter = get_and_increment_counter(counter_name)
    entropy = :crypto.strong_rand_bytes(length)
    fingerprint = create_fingerprint()

    # 2. Combine everything into a single hash
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

    # 3. Convert to Base36
    hash_integer = :binary.decode_unsigned(combined_hash)
    base36_encoded = to_base36(hash_integer)

    # 4. Add prefix and adjust length
    prefix = <<Enum.random(@cuid2_prefix)>>
    body = String.slice(base36_encoded, -(length - 1), length - 1)

    prefix <> body
  end

  @doc """
  Validates whether a string matches the CUID2 format.
  Returns `false` for any non-binary input, will not raise an error.
  """
  def is_valid?(cuid) when is_binary(cuid) do
    Regex.match?(~r/^[a-z][a-z0-9]{23,31}$/, cuid)
  end

  def is_valid?(_other), do: false

  # --- Private Functions ---

  # Atomically gets and increments the counter using the Agent.
  # Guarded for internal robustness.
  defp get_and_increment_counter(counter_name) do
    Agent.get_and_update(counter_name, fn state ->
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

  # Converts an integer to a Base36 string.
  # Guarded for internal robustness.
  defp to_base36(number) do
    Stream.unfold(number, fn
      0 -> nil
      n -> {rem(n, @cuid2_base), div(n, @cuid2_base)}
    end)
    |> Enum.map(&Enum.at(@base36_chars, &1))
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end
end

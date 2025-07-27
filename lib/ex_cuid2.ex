defmodule ExCuid2 do
  @moduledoc """
  A robust, thread-safe, and testable CUID2 (Collision-Resistant Unique Identifiers) generator for Elixir.

  This implementation follows the CUID2 standard and generates safe, horizontally scalable IDs,
  ideal for use as primary keys in databases.

  Features:
  - Prefix with a random letter.
  - Timestamp in milliseconds.
  - Local Atomic counter to prevent collisions in the same millisecond.
  - Cryptographically secure entropy.
  - Process fingerprint to ensure uniqueness across nodes.
  """

  # --- Module Attributes ---

  @default_counter_name {:counter, __MODULE__}
  @fingerprint_key {:fingerprint, __MODULE__}

  @default_length 24
  @base36_chars "0123456789abcdefghijklmnopqrstuvwxyz"
  @cuid2_prefix "abcdefghijklmnopqrstuvwxyz"
  @prefix_length 26
  @cuid2_base 36

  @max_counter_value 65_535

  # Safe prefix limit to ensure that the random index does not exceed the prefix length.
  # To avoid modulo bias, we ensure that the random value is always less than this limit.
  @safe_prefix_limit div(255, @prefix_length) * @prefix_length


  # Matches CUID2 format: starts with a letter, followed by 23-31 alphanumeric characters.
  @cuid2_regex ~r/^[a-z][a-z0-9]{23,31}$/

  # --- Public API ---

  @doc """
  Generates a CUID2 with the default length and counter.
  """
  def generate(), do: generate(@default_length)

  @doc """
  Generates a CUID2 with a specific length, using the default counter.
  Raises `FunctionClauseError` if length is not an integer.
  """
  def generate(length)
      when is_integer(length) and length in 24..32 do
    # 1. Get ID components
    timestamp = System.system_time(:millisecond)
    counter = local_counter()
    entropy_bytes = :crypto.strong_rand_bytes(length)
    fingerprint = get_or_create_fingerprint()

    # 2. Combine everything into a single hash
    combined_hash =
      :crypto.hash(
        :sha256,
        [
          <<timestamp::integer-size(64)>>,  # Timestamp as a 64-bit integer
          <<counter::integer-size(16)>>,    # Counter as a 16-bit integer
          entropy_bytes,
          fingerprint
        ]
      )

    # 3. Convert to Base36
    hash_integer = :binary.decode_unsigned(combined_hash)
    base36_encoded = to_base36(hash_integer)

    # 4. Add prefix and adjust length
    prefix = secure_prefix()

    body_start = max(0, byte_size(base36_encoded) - (length - 1))
    body = binary_part(base36_encoded, body_start, min(length - 1, byte_size(base36_encoded)))

    <<prefix::binary, body::binary>>
  end

  @doc """
  Validates whether a string matches the CUID2 format.
  Returns `false` for any non-binary input, will not raise an error.
  """
  def is_valid?(cuid) when is_binary(cuid) do
    Regex.match?(@cuid2_regex, cuid)
  end

  def is_valid?(_other), do: false

  # --- Private Functions ---

  # Atomically gets and increments the counter using Process.put/2 to have a local process counter.
  # Guarded for internal robustness.
  defp local_counter do
    current = Process.get(@default_counter_name, 0)
    next_value = if current >= @max_counter_value, do: 1, else: current + 1
    Process.put(@default_counter_name, next_value)
    next_value
  end

  # Generates a secure prefix based on a random byte.
  # This ensures that the prefix is always a letter from the CUID2 prefix set.
  defp secure_prefix do
    random_index = generate_uniform_index()
    <<binary_part(@cuid2_prefix, random_index, 1)::binary>>
  end

  # Creates a process fingerprint to add more entropy
  # between different machines or application restarts.
  defp get_or_create_fingerprint do
    case Process.get(@fingerprint_key) do
      nil ->
        # Create a fingerprint based on the current process ID and node name
        pid_string = :erlang.pid_to_list(self()) |> to_string()
        node_string = Atom.to_string(Node.self())
        fingerprint = :crypto.hash(:sha256, pid_string <> node_string)
        Process.put(@fingerprint_key, fingerprint)
        fingerprint
      cached_fingerprint ->
        # Return the cached fingerprint
        cached_fingerprint
    end
  end

  # Converts an integer to a Base36 string.
  # Guarded for internal robustness.
  defp to_base36(0), do: "0"
  defp to_base36(number) when number > 0 do
    to_base36_acc(number, "")
  end

  defp to_base36_acc(0, acc), do: acc
  defp to_base36_acc(number, acc) do
    remainder = rem(number, @cuid2_base)
    char = binary_part(@base36_chars, remainder, 1)
    to_base36_acc(div(number, @cuid2_base), char <> acc)
  end


  defp generate_uniform_index do
    random_byte = :crypto.strong_rand_bytes(1)
    random_val = :binary.decode_unsigned(random_byte)

    if random_val >= @safe_prefix_limit do
      # The value is too high, we need to generate a new one.
      generate_uniform_index()
    else
      # The value is in the safe range, the modulo is now uniform.
      rem(random_val, @prefix_length)
    end
  end

end

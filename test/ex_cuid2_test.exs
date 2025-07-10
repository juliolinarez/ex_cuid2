defmodule ExCuid2Test do
  use ExUnit.Case, async: false
  doctest ExCuid2

  # Solution to Problem 1: Start the Agent before each test.
  # This ensures that `:cuid2_counter` always exists when needed.
  setup do
    name = :cuid2_counter

    # If it already exists, kill it before starting a new one
    if pid = Process.whereis(name) do
      Process.exit(pid, :kill)

      # Wait for the process to fully terminate to avoid registration conflicts
      ref = Process.monitor(pid)
      receive do
        {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
      after
        100 -> :ok
      end
    end

    {:ok, _pid} = ExCuid2.start_link([])

    :ok
  end

  test "generate/0 produces a CUID with the default length (24)" do
    cuid = ExCuid2.generate()
    assert String.length(cuid) == 24
    assert ExCuid2.is_valid?(cuid)
  end

  test "generate/1 produces a CUID with a specific length" do
    cuid = ExCuid2.generate(32)
    assert String.length(cuid) == 32
    assert ExCuid2.is_valid?(cuid)
  end

  test "generate/1 raises an error if the length is outside the allowed range" do
    assert_raise FunctionClauseError, fn ->
      ExCuid2.generate(23)
    end

    assert_raise FunctionClauseError, fn ->
      ExCuid2.generate(33)
    end
  end

  test "is_valid?/1 returns true for a valid CUID" do
    cuid = ExCuid2.generate()
    assert ExCuid2.is_valid?(cuid)
  end

  test "is_valid?/1 returns false for an invalid CUID" do
    refute ExCuid2.is_valid?("not-a-cuid")
    refute ExCuid2.is_valid?("123456789012345678901234") # Does not start with a letter
    refute ExCuid2.is_valid?(nil)
  end

  test "Uniqueness test: generates unique IDs in high-volume bursts" do
    count = 20_000
    ids = for _ <- 1..count, do: ExCuid2.generate()
    unique_ids = Enum.uniq(ids)

    assert length(unique_ids) == count
  end
end

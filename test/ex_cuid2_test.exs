defmodule ExCuid2Test do
  use ExUnit.Case, async: true
  doctest ExCuid2

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
    cuid_24 = ExCuid2.generate()
    assert ExCuid2.is_valid?(cuid_24)
    cuid_32 = ExCuid2.generate(32)
    assert ExCuid2.is_valid?(cuid_32)
  end

  test "is_valid?/1 returns false for an invalid CUID" do
    refute ExCuid2.is_valid?("not-a-cuid")
    refute ExCuid2.is_valid?("123456789012345678901234") # Does not start with a letter
    refute ExCuid2.is_valid?(nil)
  end

  test "Uniqueness test: generates unique IDs in high-volume bursts" do
    count = 50_000
    ids = for _ <- 1..count, do: ExCuid2.generate()
    unique_ids = Enum.uniq(ids)

    assert length(unique_ids) == count
  end

  describe "custom-named agent behavior" do
    # This setup starts an agent with a name WE provide.
    setup do
      ExCuid2.start_link(name: :my_test_counter)
      :ok
    end

    test "generate/2 with a custom name uses and increments the correct agent" do
      # Verify our custom agent is at 0.
      assert Agent.get(:my_test_counter, & &1) == 0

      # Call the function, explicitly passing the name of our custom agent.
      ExCuid2.generate(24, :my_test_counter) # Custom counter becomes 1
      ExCuid2.generate(28, :my_test_counter) # Custom counter becomes 2

      # Assert that the custom counter was incremented.
      final_custom_count = Agent.get(:my_test_counter, & &1)
      assert final_custom_count == 2
    end
  end

end

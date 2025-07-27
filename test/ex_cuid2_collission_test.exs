# test/ex_cuid2_collision_test.exs

defmodule ExCuid2CollisionTest do
  use ExUnit.Case, async: true

  # This test checks for collisions in a realistic scenario with multiple concurrent workers.
  # It generates a large number of CUIDs across multiple processes and ensures that no two
  # generated CUIDs are the same, simulating a high-load environment where many IDs
  # are generated at the same time.

  test "generates no collisions across concurrent workers" do
    num_workers = 4
    ids_per_worker = 250_000
    total_ids = num_workers * ids_per_worker

    IO.puts("Starting realistic collision test...")

    all_ids =
      Task.async_stream(1..num_workers, fn _worker_id ->
        IO.puts "PID worker: #{inspect self()}"
        ids = for _ <- 1..ids_per_worker do
          ExCuid2.generate(24)
        end
        IO.puts "worker finished: #{inspect Process.get({:counter, ExCuid2}, 0)}"
        ids
      end,
      timeout: 60_000)
      |> Enum.map(fn {:ok, ids} -> ids end)
      |> List.flatten()

    IO.puts("All IDs #{total_ids} have been generated. Checking for collisions...")

    assert length(Enum.uniq(all_ids)) == total_ids

    IO.puts("Success! No collisions found in a concurrent environment.")
  end
end

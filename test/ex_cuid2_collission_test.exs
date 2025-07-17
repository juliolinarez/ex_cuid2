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


    worker_counters =
      for i <- 1..num_workers do
        {:ok, pid} = ExCuid2.start_link(name: :"cuid2_counter_#{i}")
        pid
      end

    # We use `Task.async_stream/3` to generate IDs concurrently across multiple worker processes.
    # Each process will have a different counter and fingerprint.
    # This simulates a realistic scenario where multiple processes generate IDs at the same time.
    all_ids =
      Task.async_stream(worker_counters, fn counter_pid ->
        for _ <- 1..ids_per_worker do
          ExCuid2.generate(24, counter_pid)
        end
      end,
      timeout: 60_000)
      |> Enum.map(fn {:ok, ids} -> ids end)
      |> List.flatten()

    IO.puts("All IDs #{length(all_ids)} have been generated. Checking for collisions...")

    assert length(Enum.uniq(all_ids)) == total_ids

    IO.puts("Success! No collisions found in a concurrent environment.")
  end
end

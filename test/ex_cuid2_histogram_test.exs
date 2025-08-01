defmodule ExCuid2.HistogramTest do
  use ExUnit.Case, async: false # Run sequentially to get clean IO output

  # --- Module Attributes ---
  @num_samples 1_000_000
  @body_alphabet "abcdefghijklmnopqrstuvwxyz0123456789" # 36 chars
  @first_letter_alphabet "abcdefghijklmnopqrstuvwxyz" # 26 chars
  @tolerance_percent 0.03 # 3% tolerance for uniform distribution

  @tag :histogram
  test "distribution is uniform for both first letter and body across 1 million samples" do

    IO.puts("Generating #{@num_samples} CUID2 samples... (this may take a moment)")

    all_ids =
      Task.async_stream(1..5, fn _worker_id ->
        ids = for _ <- 1..200_000 do
          ExCuid2.generate(24)
        end
        ids
      end,
      timeout: 60_000)
      |> Enum.map(fn {:ok, ids} -> ids end)
      |> List.flatten()


    first_letter_frequencies =
      all_ids
      |> Stream.map(&String.first/1)
      |> Enum.frequencies()

    first_letter_total_chars = @num_samples
    first_letter_num_distinct_chars = String.length(@first_letter_alphabet)
    first_letter_expected_avg = first_letter_total_chars / first_letter_num_distinct_chars
    first_letter_tolerance_threshold = first_letter_expected_avg * @tolerance_percent

    Enum.each(first_letter_frequencies, fn {char, count} ->
      deviation = abs(count - first_letter_expected_avg)

      assert deviation <= first_letter_tolerance_threshold,
             "High Deviation for First Letter! Character '#{char}' is outside the tolerance range."
    end)

    body_frequencies =
      all_ids
      |> Stream.map(&String.slice(&1, 1..-1//1))
      |> Stream.flat_map(&String.graphemes/1)
      |> Enum.frequencies()

    body_total_chars = Enum.sum(Map.values(body_frequencies))
    body_num_distinct_chars = String.length(@body_alphabet)
    body_expected_avg = body_total_chars / body_num_distinct_chars
    body_tolerance_threshold = body_expected_avg * @tolerance_percent

    Enum.each(body_frequencies, fn {char, count} ->
      deviation = abs(count - body_expected_avg)

      assert deviation <= body_tolerance_threshold,
             "High Deviation for Body! Character '#{char}' is outside the tolerance range."
    end)

    IO.puts("\n✅ All Assertions Passed: Distribution is within tolerance for all parts.")


    first_letter_devs =
      Enum.map(first_letter_frequencies, fn {char, count} ->
        %{char: char, dev: count - first_letter_expected_avg}
      end)

    max_pos_dev_first = Enum.max_by(first_letter_devs, & &1.dev)
    max_neg_dev_first = Enum.min_by(first_letter_devs, & &1.dev)
    max_pos_perc_first = (max_pos_dev_first.dev / first_letter_expected_avg) * 100
    max_neg_perc_first = (max_neg_dev_first.dev / first_letter_expected_avg) * 100

    IO.puts("\n--- First Letter Analysis (a-z) ---")
    IO.puts("Expected Avg. Count:       #{round(first_letter_expected_avg)}")
    IO.puts("Tolerance:                 #{@tolerance_percent * 100}% (Threshold: ±#{round(first_letter_tolerance_threshold)})")
    IO.puts(
      "Max Positive Deviation:    '#{max_pos_dev_first.char}' with +#{round(max_pos_dev_first.dev)} (#{Float.round(max_pos_perc_first, 2)}%)"
    )
    IO.puts(
      "Max Negative Deviation:    '#{max_neg_dev_first.char}' with #{round(max_neg_dev_first.dev)} (#{Float.round(max_neg_perc_first, 2)}%)"
    )

    body_devs =
      Enum.map(body_frequencies, fn {char, count} ->
        %{char: char, dev: count - body_expected_avg}
      end)

    max_pos_dev_body = Enum.max_by(body_devs, & &1.dev)
    max_neg_dev_body = Enum.min_by(body_devs, & &1.dev)
    max_pos_perc_body = (max_pos_dev_body.dev / body_expected_avg) * 100
    max_neg_perc_body = (max_neg_dev_body.dev / body_expected_avg) * 100

    IO.puts("\n--- ID Body Analysis (a-z, 0-9) ---")
    IO.puts("Expected Avg. Count:       #{round(body_expected_avg)}")
    IO.puts("Tolerance:                 #{@tolerance_percent * 100}% (Threshold: ±#{round(body_tolerance_threshold)})")
    IO.puts(
      "Max Positive Deviation:    '#{max_pos_dev_body.char}' with +#{round(max_pos_dev_body.dev)} (#{Float.round(max_pos_perc_body, 2)}%)"
    )
    IO.puts(
      "Max Negative Deviation:    '#{max_neg_dev_body.char}' with #{round(max_neg_dev_body.dev)} (#{Float.round(max_neg_perc_body, 2)}%)"
    )
    IO.puts("-----------------------------------")
  end
end

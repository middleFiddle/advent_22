# Run as: iex --dot-iex path/to/notebook.exs

# Title: Advent of Code Day 6

Mix.install([
  {:kino, github: "livebook-dev/kino"}
])

# ── Section ──

input = Kino.Input.textarea("Please paste your input")

day6 = Kino.Input.read(input)

day6_list = String.split(day6, "", trim: true)

defmodule TuneUp do
  def find_first_n_uniq(list, step, count) do
    indexed = Enum.with_index(list)
    window = Enum.take(indexed, step)

    internal = length(Enum.uniq(Enum.map(window, fn x -> elem(x, 0) end))) === step

    if internal do
      count
    else
      count = count + 1
      find_first_n_uniq(tl(list), step, count)
    end
  end
end

TuneUp.find_first_n_uniq(day6_list, 14, 14)

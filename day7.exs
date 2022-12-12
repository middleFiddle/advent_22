# Run as: iex --dot-iex path/to/notebook.exs

# Title: Advent of Code Day 7

Mix.install([{:kino, github: "livebook-dev/kino"}])

# ── Section ──

day7 = Kino.Input.textarea("Let's see our terminal commands and outputs")

test = Kino.Input.textarea("Example here")

terminal = Kino.Input.read(day7)

terminal = String.split(terminal, "\n")

terminal =
  terminal
  |> Enum.filter(fn x -> x != "$ cd .." end)
  |> Enum.flat_map(&[String.split(&1, "d ")])
  |> Enum.chunk_by(&("$ c" == hd(&1)))
  |> Enum.chunk_every(2)
  |> Enum.map(&[Enum.join(hd(&1), "") | List.flatten(tl(&1))])
  |> Enum.map(&[String.slice(hd(&1), 3..String.length(hd(&1))) | List.flatten(tl(&1))])
  |> Enum.map(&[String.to_atom(hd(&1)) | List.flatten(tl(tl(&1)))])

# so far, we have collected the conteents that are listed under each cd ls combo.  the name of each directory called by "cd" has been extracted into an atom, "ls" is irrelevant, so it has been discarded

# next, let's find all "dir _" examples, and convert them to atoms as well

terminal =
  terminal
  |> Enum.map(&[hd(&1) | Enum.map(tl(&1), fn x -> String.split(x, " ") end)])
  |> Enum.map(
    &[
      hd(&1)
      | Enum.map(tl(&1), fn x ->
          if hd(x) == "dir" do
            String.to_atom(hd(tl(x)))
          else
            x
          end
        end)
    ]
  )

# finally, let's make extract integers from each "file" list

terminal =
  terminal
  |> Enum.map(
    &[
      hd(&1)
      | Enum.map(tl(&1), fn x ->
          if is_list(x) do
            String.to_integer(hd(x))
          else
            x
          end
        end)
    ]
  )

length(terminal)

# Our Dir algorithm cannot handle large lists.

# Let's try an implemenntation that handles a keyword list to enhance the performance our look up operations.

defmodule Functions do
  def prioritize_atoms(list) do
    list
    |> Enum.sort()
    |> Enum.reverse()
  end

  def which_to_reduce(keyword, row) do
    ready_to_sum? = Enum.all?(row, &is_integer(&1))

    if ready_to_sum? do
      row
    else
      priority = prioritize_atoms(row)

      sums =
        priority
        |> Enum.filter(fn x -> is_atom(x) end)
        |> Enum.map(&Keyword.get(keyword, &1))
        |> List.flatten()

      which_to_reduce(keyword, [hd(sums) | tl(priority)])
    end
  end

  def reduction(keyword, k) do
    {_old, new} =
      Keyword.get_and_update(
        keyword,
        k,
        fn x -> {x, Functions.which_to_reduce(keyword, x)} end
      )

    new[k]
    |> Enum.sum()
  end

  def map_over_keys(keyword) do
    keys =
      Keyword.keys(keyword)
      |> Enum.map(&reduction(keyword, &1))
  end
end

atoms_prioritized =
  terminal
  |> Enum.map(&tl(&1))
  |> Enum.map(&Functions.prioritize_atoms(&1))

keys =
  terminal
  |> Enum.map(&hd(&1))

keyword =
  Enum.zip(keys, atoms_prioritized)
  |> Keyword.new()

Functions.map_over_keys(keyword)
|> Enum.filter(fn x -> x < 100_000 end)
|> Enum.sum()

length(keyword)

length(Functions.map_over_keys(keyword))

# Per Key list

# we recursively process the row until:

# the base case is reached -> we could stop when every key contains an integer OR
# instead, let's reach the base case where every atom in the list has been replaced

# The base case is reached when ALL elements of the list of integers,

n = length(terminal)

defmodule Naive_One do
  def find_and_fill(atom, lists) do
    lists
    |> Enum.filter(&(hd(&1) == atom))
    |> Enum.flat_map(&tl(&1))
  end

  def handle_content(term) do
    root = hd(term)
    root_contents = tl(root)
    dir_lists = tl(term)

    root_contents =
      root_contents
      |> Enum.map(
        &if is_atom(&1) do
          Dir.find_and_fill(&1, dir_lists)
        else
          &1
        end
      )

    flat_contents = List.flatten(root_contents)
    result = [[hd(root) | flat_contents] | dir_lists]

    if Enum.any?(flat_contents, fn x -> is_atom(x) end) do
      handle_content(result)
    else
      result
    end
  end

  def parent_call(terminal) do
    first_fix = handle_content(terminal)
    wo_key = Enum.map(first_fix, &tl(&1))
    again? = Enum.any?(List.flatten(wo_key), fn x -> is_atom(x) end)

    if again? do
      tail = parent_call(tl(first_fix))
      [hd(first_fix) | tail]
    else
      fix = handle_content(tl(first_fix))
      [hd(first_fix) | fix]
    end
  end
end

ready_to_sum = Naive_One.parent_call(terminal)

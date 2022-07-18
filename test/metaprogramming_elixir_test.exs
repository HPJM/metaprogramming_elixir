defmodule MetaprogrammingElixirTest do
  use ExUnit.Case
  doctest MetaprogrammingElixir

  test "greets the world" do
    assert MetaprogrammingElixir.hello() == :world
  end
end

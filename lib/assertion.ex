defmodule MetaprogrammingElixir.Assertion do
  defmacro __using__(_opts) do
    IO.puts("__using__")

    quote do
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :tests, accumulate: true)

      @before_compile unquote(__MODULE__)
      @after_compile unquote(__MODULE__)
    end
  end

  # Delay injection of run until just before compilation finishes, when we have all the @tests values
  defmacro __before_compile__(_env) do
    IO.puts("__before_compile__")

    quote do
      def run do
        unquote(__MODULE__).Test.run(@tests, __MODULE__)
      end
    end
  end

  def __after_compile__(_env, _bytecode) do
    IO.puts("__after_compile__")
  end

  defmacro test(description, do: test_block) do
    test_func = String.to_atom(description)
    IO.puts("test")

    quote do
      @tests {unquote(test_func), unquote(description)}

      def unquote(test_func)(), do: unquote(test_block)
    end
  end

  defmacro assert({operator, _, [lhs, rhs]}) do
    quote bind_quoted: [operator: operator, lhs: lhs, rhs: rhs] do
      MetaprogrammingElixir.Assertion.Test.assert(operator, lhs, rhs)
    end
  end
end

defmodule MetaprogrammingElixir.Assertion.Test do
  def assert(:==, lhs, rhs) when lhs == rhs do
    :ok
  end

  def assert(:==, lhs, rhs) do
    {:fail,
     """
     Expected:       #{lhs}
     to be equal to: #{rhs}
     """}
  end

  def assert(:>, lhs, rhs) when lhs > rhs do
    :ok
  end

  def assert(:>, lhs, rhs) do
    {:fail,
     """
     Expected:           #{lhs}
     to be greater than: #{rhs}
     """}
  end

  def run(tests, module) do
    Enum.each(tests, fn {test_func, description} ->
      case apply(module, test_func, []) do
        :ok ->
          IO.write(".")

        {:fail, reason} ->
          equals = String.duplicate("=", 32)

          IO.puts("""
          #{equals}
          FAILURE: #{description}
          #{equals}
          #{reason}
          """)
      end
    end)
  end
end

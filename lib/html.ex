defmodule MetaprogrammingElixir.HTML do
  @external_resource tags_path = Path.join(__DIR__, "tags.txt")
  @tags (for line <- File.stream!(tags_path, [], :line) do
           line |> String.trim() |> String.to_atom()
         end)

  # Generate these more efficiently below by walking the AST

  # for tag <- @tags do
  #   defmacro unquote(tag)(attrs, do: inner) do
  #     tag = unquote(tag)

  #     quote do
  #       tag(unquote(tag), unquote(attrs)) do
  #         unquote(inner)
  #       end
  #     end
  #   end

  #   defmacro unquote(tag)(attrs \\ []) do
  #     tag = unquote(tag)

  #     quote do
  #       tag(unquote(tag), unquote(attrs))
  #     end
  #   end
  # end

  defmacro markup(do: block) do
    quote do
      import Kernel, except: [div: 2]

      {:ok, var!(buffer, MetaprogrammingElixir.HTML)} = start_buffer([])
      unquote(Macro.postwalk(block, &postwalk/1))
      result = render(var!(buffer, MetaprogrammingElixir.HTML))
      :ok = stop_buffer(var!(buffer, MetaprogrammingElixir.HTML))

      result
    end
  end

  def postwalk({:text, _meta, [string]}) do
    quote do
      put_buffer(var!(buffer, MetaprogrammingElixir.HTML), to_string(unquote(string)))
    end
  end

  def postwalk({tag_name, _meta, [[do: inner]]}) when tag_name in @tags do
    quote do
      tag(unquote(tag_name), [], do: unquote(inner))
    end
  end

  def postwalk({tag_name, _meta, [attrs, [do: inner]]}) when tag_name in @tags do
    quote do
      tag(unquote(tag_name), unquote(attrs), do: unquote(inner))
    end
  end

  def postwalk(ast), do: ast

  def start_buffer(state) do
    Agent.start_link(fn -> state end)
  end

  def stop_buffer(buff), do: Agent.stop(buff)

  def put_buffer(buff, content) do
    Agent.update(buff, &[content | &1])
  end

  def render(buff) do
    buff |> Agent.get(& &1) |> Enum.reverse() |> Enum.join("")
  end

  # Clause for tags which have no attributes
  defmacro tag(name, attrs \\ []) do
    {inner, attrs} = Keyword.pop!(attrs, :do)

    quote do
      tag(unquote(name), unquote(attrs), do: unquote(inner))
    end
  end

  defmacro tag(name, attrs, do: inner) do
    quote do
      put_buffer(
        var!(buffer, MetaprogrammingElixir.HTML),
        open_tag(unquote_splicing([name, attrs]))
      )

      unquote(inner)
      put_buffer(var!(buffer, MetaprogrammingElixir.HTML), "</#{unquote(name)}>")
    end
  end

  def open_tag(name, []) do
    "<#{name}>"
  end

  def open_tag(name, attrs) do
    attr_html =
      for {k, v} <- attrs, into: "" do
        " #{k}=\"#{v}\""
      end

    "<#{name}#{attr_html}>"
  end

  # defmacro text(string) do
  #   quote do
  #     buffer |> var!(MetaprogrammingElixir.HTML) |> put_buffer(to_string(unquote(string)))
  #   end
  # end
end

defmodule MetaprogrammingElixir.Template do
  import MetaprogrammingElixir.HTML

  def render do
    markup do
      div id: "main" do
        h1 class: "title" do
          text("Welcome!")
        end
      end

      div class: "row" do
        div do
          p(do: text("Hello!"))
        end
      end
    end
  end
end

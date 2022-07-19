defmodule MetaprogrammingElixir.Hub do
  @username "HPJM"
  HTTPoison.start()

  "https://api.github.com/users/#{@username}/repos"
  |> HTTPoison.get!()
  |> Map.fetch!(:body)
  |> Jason.decode!()
  |> Enum.map(fn repo ->
    def unquote(String.to_atom(repo["name"]))() do
      unquote(Macro.escape(repo))
    end
  end)

  def go(repo) do
    url = apply(__MODULE__, repo, [])["html_url"]
    IO.puts("Launching browser to #{url}...")
    System.cmd("open", [url])
  end
end

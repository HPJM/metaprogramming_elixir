defmodule MetaprogrammingElixir.I18n do
  use MetaprogrammingElixir.Translator

  locale("en",
    flash: [
      hello: "Hello %{first} %{last}!",
      bye: "Bye, %{name}!"
    ],
    users: [
      title: "Users"
    ]
  )

  locale("fr",
    flash: [
      hello: "Salut %{first} %{last}!",
      bye: "Au revoir, %{name}!"
    ],
    users: [
      title: "Utilisateurs"
    ]
  )
end

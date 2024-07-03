defmodule UserAsTable do
  defstruct [:id]

  defimpl Kino.Render do
    def to_livebook(user) do
      Kino.DataTable.new([%{id: user.id}]) |> Kino.Render.to_livebook()
    end
  end
end

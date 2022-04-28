defmodule Kino.LivebookCase do
  use ExUnit.CaseTemplate

  import KinoTest

  using do
    quote do
      import KinoTest
    end
  end

  setup :configure_livebook_bridge
end

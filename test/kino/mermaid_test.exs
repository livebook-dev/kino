defmodule Kino.MermaidTest do
  use Kino.LivebookCase, async: true

  test "export" do
    content = """
    graph TD;
      A-->B;
      A-->C;
      B-->D;
      C-->D;
    """

    kino = Kino.Mermaid.new(content)

    assert export(kino) == {"mermaid", content}
  end
end

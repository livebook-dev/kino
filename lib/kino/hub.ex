defmodule Kino.Hub do
  @moduledoc false

  @deprecated "Use Kino.Workspace.app_info/0 instead"
  defdelegate app_info(), to: Kino.Workspace
end

defmodule Kino.TestModules.JSInlineAssets do
  use Kino.JS

  asset "main.js" do
    """
    export function init(ctx, data) {
      console.log(data);
    }
    """
  end

  asset "main.css" do
    """
    body {
      padding: 16px;
    }
    """
  end
end

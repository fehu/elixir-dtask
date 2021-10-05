defmodule DTask.TUI.Util.TestPanel do
  @moduledoc false


  @enforce_keys [:title]
  defstruct [:title, :height, :show]

  @type height :: non_neg_integer | :fill | nil

  @type t :: %__MODULE__{
               title: String.t,
               height: height,
               show: term
             }

  @type opt :: {:height, height}
             | {:show, term}
end

alias DTask.TUI.Util.Render
alias DTask.TUI.Util.TestPanel

defimpl Render, for: TestPanel do
  import Ratatouille.View

  import DTask.Util.Syntax

  @spec render(TestPanel.t, term, [TestPanel.opt]) :: Render.result
  def render(t, _, opts0) do
    opts = opts0 <|> []
    height = Keyword.get(opts, :height) <|> Map.get(t, :height)
    show   = Keyword.get(opts, :show)   <|> Map.get(t, :show)
    panel title: t.title, height: height do
      if show,
         do: label(content: inspect(show, pretty: true, width: 0)),
         else: []
    end
  end
end

defmodule DTask.TUI.Util.TestPanel do
  @moduledoc false


  @enforce_keys [:title]
  defstruct [:title, :height]

  @type height :: non_neg_integer | :fill | nil

  @type t :: %__MODULE__{
               title: String.t,
               height: height
             }

  @type opt :: {:height, height}
end

alias DTask.TUI.Util.Render
alias DTask.TUI.Util.TestPanel

defimpl Render, for: TestPanel do
  import Ratatouille.View

  import DTask.Util.Syntax

  @spec render(TestPanel.t, term, [TestPanel.opt]) :: Render.result
  def render(t, _, opts) do
    height = Keyword.get(opts <|> [], :height) <|> Map.get(t, :height)
    panel title: t.title, height: height do

    end
  end
end

defprotocol DTask.TUI.Render do
  alias Ratatouille.Renderer.Element

  @type state :: term

  @callback render(state) :: Element.t()
end

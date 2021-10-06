defprotocol DTask.TUI.Render do
  alias Ratatouille.Renderer.Element

  @callback render(DTask.TUI.state) :: Element.t()
end

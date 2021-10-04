defprotocol DTask.TUI.Util.Render do
  alias Ratatouille.Renderer.Element

  @type model  :: term
  @type cfg    :: term
  @type result :: Element.t()

  @spec render(t, model, cfg) :: result
  def render(t, model, cfg)
end

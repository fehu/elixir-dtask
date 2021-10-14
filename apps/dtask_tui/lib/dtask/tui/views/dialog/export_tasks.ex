defmodule DTask.TUI.Views.Dialog.ExportTasks do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Views
  alias DTask.TUI.Views.{Input, Stateful}

  import DTask.Util.Syntax, only: [<|>: 2]

  use Views.Dialog

  @overlay_id :export_tasks

  @impl Views.Dialog
  def overlay_id, do: @overlay_id

  @type cfg :: %{
                 optional(:initial_path) => charlist | String.t
               }

  @impl Views.Dialog
  @spec overlay(TUI.state, cfg) :: TUI.Overlay.t
  def overlay(state, cfg), do: %TUI.Overlay{
    id: @overlay_id,
    render: __MODULE__,
    padding: 5,
    stateful: Stateful.create_many [
      {__MODULE__.FileInput,
        &__MODULE__.FileInput.set_text(&1, state, cfg[:initial_path] <|> "", cursor: :last)}
    ]
  }

  @impl Views.Dialog
  @spec title(TUI.state) :: String.t
  def title(_), do: "Export tasks to file"

  @impl Views.Dialog
  @spec body(TUI.state) :: [Element.t]
  def body(state),
      do: [
        __MODULE__.FileInput.render(state)
      ]

  @impl Views.Dialog
  @spec buttons(TUI.state) :: [String.t]
  def buttons(_state), do: ["[Esc] Cancel", "[Enter] OK"]


  defmodule FileInput do
    @fixed_width_input 4 * 2 + 1

    use Input.TextLine
    use Stateful.OneLineInput,
        long_sep: Input.TextLine.Path.long_sep,
        short_sep: Input.TextLine.Path.short_sep

    @impl Input.TextLine
    @impl Stateful.OneLineInput
    @spec input_width(TUI.state) :: non_neg_integer
    def input_width(state) do
      overlay_id = DTask.TUI.Views.Dialog.ExportTasks.overlay_id
      TUI.Overlay.width(state, overlay_id) - @fixed_width_input
    end
  end

end

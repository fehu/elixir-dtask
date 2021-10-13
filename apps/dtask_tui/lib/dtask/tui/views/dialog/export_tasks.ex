defmodule DTask.TUI.Views.Dialog.ExportTasks do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Views
  alias DTask.TUI.Views.{Input, Stateful}

  import DTask.Util.Syntax, only: [<|>: 2]

  use Views.Dialog

  @type cfg :: %{
                 optional(:initial_path) => charlist | String.t
               }

  @impl Views.Dialog
  @spec overlay(TUI.state, cfg) :: TUI.Overlay.t
  def overlay(state, cfg), do: %TUI.Overlay{
    id: :export_tasks,
    render: __MODULE__,
    stateful: Stateful.create_many [
      {__MODULE__.FileInput,
        &__MODULE__.FileInput.set_text(&1, state, cfg[:initial_path] <|> "", cursor: :last)}
    ]
  }

  @impl Views.Dialog
  @spec title(TUI.state) :: String.t
  def title(_), do: "Export Task(s)"

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
    @spec title(TUI.State.t) :: String.t
    def title(_), do: "Export into file: "

    @impl Input.TextLine
    @impl Stateful.OneLineInput
    @spec input_width(TUI.state) :: non_neg_integer
    def input_width(state) do
      TUI.Overlay.width(state) - @fixed_width_input
    end
  end

end

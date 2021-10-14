defmodule DTask.TUI.Views.Dialog.ExportTasks do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Views
  alias DTask.TUI.Views.{Input, Stateful}

  import DTask.Util.Syntax, only: [<|>: 2]

  use Views.Dialog

  @stateful_id :export_tasks

  @impl Views.Dialog
  def stateful_id, do: @stateful_id

  @type cfg :: %{
                 optional(:initial_path) => charlist | String.t
               }

  @impl Views.Dialog
  @spec overlay(TUI.state, cfg) :: TUI.Overlay.t
  def overlay(state, cfg), do: %TUI.Overlay{
    id: @stateful_id,
    render: __MODULE__,
    padding: 5,
    stateful: Stateful.create_many [
      {__MODULE__.FileInput,
        &__MODULE__.FileInput.set_text(&1, state, cfg[:initial_path] <|> "", cursor: :last)},
      __MODULE__.React
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

    alias DTask.TUI.Views.Dialog.ExportTasks

    use Input.TextLine
    use Stateful.OneLineInput,
        long_sep: Input.TextLine.Path.long_sep,
        short_sep: Input.TextLine.Path.short_sep

    @impl Input.TextLine
    @impl Stateful.OneLineInput
    @spec input_width(TUI.state) :: non_neg_integer
    def input_width(state) do
      TUI.Overlay.width(state, ExportTasks.stateful_id) - @fixed_width_input
    end

    @impl Input.TextLine
    @spec stateful_id :: atom
    defdelegate stateful_id, to: DTask.TUI.Views.Dialog.ExportTasks

    @spec get_text(TUI.state) :: String.t | nil
    def get_text(state) do
      overlay = TUI.Overlay.find(state, ExportTasks.stateful_id)
      if overlay, do: overlay.stateful.state[__MODULE__.state_key].text
    end
  end

  defmodule React do
    use DTask.TUI.Util.Keys
    use Stateful.Reactive,
        bind: %{
          %{key: @enter} => {:external, [{:save_file, []}]}
        }

    @impl true
    def state_key, do: :save_file

    # TODO ========================================================================
    @spec save_file(Path.t | nil, boolean) :: (TUI.state -> Stateful.react_external)
    def save_file(file \\ nil, overwrite \\ false), do: fn state ->
      file = if file, do: file, else: Views.Dialog.ExportTasks.FileInput.get_text(state)
      # TODO
      data = "test"
      opts = unless overwrite, do: [:exclusive], else: []
      case File.write(file, data, opts) do
        :ok               -> :close_overlay
        {:error, :eexist} -> {:open_overlay, overwrite_dialog(state, file)}
        {:error, error}   -> {:error, error} # TODO
      end
    end

    @max_padding 6
    defp overwrite_dialog(state, file) do
      padding = fn s ->
        p = round(s.ui.window.height / 3)
        if s.ui.window.height - 2 * p < 10,
           do: @max_padding,
           else: p
      end
      Views.Dialog.YesNo.overlay %{
        title: "Overwrite?",
        text: "File already exists, overwrite it?\n\n#{file}",
        padding: padding,
        yes: fn -> [:close_overlay, __MODULE__.save_file(file, true).(state)] end
      }
    end
  end

end

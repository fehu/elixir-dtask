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
    alias DTask.Task.{Codec, Dispatcher, DTO, Monitor}

    @codec Codec.Json

    use DTask.TUI.Util.Keys
    use Stateful.Reactive,
        bind: %{
          %{key: @enter} => {:external, [{:save_file, []}]}
        }

    @impl true
    def state_key, do: :save_file

    # TODO: handle errors
    @spec save_file(Path.t | nil, boolean) :: (TUI.state -> [Stateful.react_external])
    def save_file(file \\ nil, overwrite \\ false), do: fn state ->
      file = if file, do: file, else: Views.Dialog.ExportTasks.FileInput.get_text(state)
      data = Enum.map(state.data.tasks, &task_to_dto/1)

      with {:ok, data} <- @codec.encode(data) do
        opts = unless overwrite, do: [:exclusive], else: []
        # Do write file
        case File.write(file, data, opts) do
          :ok               -> [:close_overlay, {:open_overlay, ok_dialog(state, file)}]
          {:error, :eexist} -> [{:open_overlay, overwrite_dialog(state, file)}]
          {:error, error}   -> {:error, error} # TODO
        end
      else
        {:error, error}   -> {:error, error} # TODO
      end
    end

    defp overwrite_dialog(state, file) do
      Views.Dialog.YesNo.overlay %{
        title: "Overwrite?",
        text: "File already exists, overwrite it?\n\n#{file}",
        padding: &padding/1,
        yes: fn -> [:close_overlay | __MODULE__.save_file(file, true).(state)] end
      }
    end

    defp ok_dialog(state, file) do
      Views.Dialog.Message.overlay(%{
        title: "File saved!",
        text: to_string(file),
        padding: &padding/1
      })
    end

    @max_padding 6
    @min_height  10
    defp padding(state) do
      padding = round(state.ui.window.height / 3)
      if state.ui.window.height - 2 * padding < @min_height,
         do: @max_padding,
         else: padding
    end

    @spec task_to_dto({Dispatcher.task_id, {Dispatcher.task_descriptor, Monitor.task_state}}) :: DTO.Task.t
    defp task_to_dto({id, {{task, params}, state}}) do
      {dispatched, finished} = case state do
        :pending ->
          {nil, nil}
        {:running, s}  ->
          {
            DTO.Task.Dispatched.new(s.node, s.dispatched),
            nil
          }
        {:finished, s=%{outcome: {outcome, result}}} ->
          {
            DTO.Task.Dispatched.new(s.node, s.dispatched),
            DTO.Task.Finished.new(outcome, result, s.finished)
          }
      end

      DTO.Task.new(id, task, params, dispatched, finished)
    end
  end

end

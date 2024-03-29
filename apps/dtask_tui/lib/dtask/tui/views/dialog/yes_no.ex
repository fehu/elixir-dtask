defmodule DTask.TUI.Views.Dialog.YesNo do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Views
  alias DTask.TUI.Views.Stateful

  import DTask.TUI.Views.Dialog.Util, only: [get_cfg!: 3]
  import DTask.Util.Syntax, only: [>>>: 2]

  use Views.Dialog

  @stateful_id :yes_no

  @button_cancel "[Esc] Cancel"
  @button_no     "[N]o"
  @button_yes    "[Y]es"

  @default_padding 10

  @impl Views.Dialog
  def stateful_id, do: @stateful_id

  @type cfg :: %{
                 required(:title) => charlist | String.t,
                 optional(:text) => charlist | String.t,
                 optional(:padding) => non_neg_integer | (TUI.state -> non_neg_integer),
                 optional(:show_cancel) => boolean,
                 required(:yes) => (-> Stateful.react_external),
                 optional(:no) => (-> Stateful.react_external)
               }

  @impl Views.Dialog
  @spec overlay(cfg) :: TUI.Overlay.t
  def overlay(cfg), do: %TUI.Overlay{
    id: @stateful_id,
    cfg: cfg,
    render: __MODULE__,
    padding: Map.get(cfg, :padding, @default_padding),
    stateful: Stateful.create(__MODULE__.React)
  }

  @impl Views.Dialog
  @spec title(TUI.state) :: String.t
  def title(state), do: to_string get_cfg!(@stateful_id, :title, nil).(state)

  @impl Views.Dialog
  @spec body(TUI.state) :: [Element.t]
  def body(state) do
    case get_cfg!(@stateful_id, :text, "").(state) do
      "" -> []
      txt -> [label(content: to_string(txt))]
    end
  end

  @impl Views.Dialog
  @spec buttons(TUI.state) :: [String.t | {String.t, keyword}]
  def buttons(state) do
    yes_no = [@button_no, @button_yes]
    if get_cfg!(@stateful_id, :show_cancel, false).(state),
       do: [@button_cancel | yes_no],
       else: yes_no
  end


  defmodule React do
    alias DTask.TUI.Views.Dialog.YesNo

    @default_no :close_overlay

    use DTask.TUI.Util.Keys
    use Stateful.Reactive,
        bind: %{
          %{ch: ?n} => {:external, [{:no, []}]},
          %{ch: ?N} => {:external, [{:no, []}]},
          %{ch: ?y} => {:external, [{:yes, []}]},
          %{ch: ?Y} => {:external, [{:yes, []}]},
        }

    @impl true
    def state_key, do: nil

    def yes, do: get_cfg!(YesNo.stateful_id, :yes, nil) >>> &(&1.())
    def no,  do: get_cfg!(YesNo.stateful_id, :no, fn -> @default_no end) >>> &(&1.())
  end

end

defmodule DTask.TUI.Views.Dialog.YesNo do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Views
  alias DTask.TUI.Views.Stateful

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
                 optional(:padding) => non_neg_integer,
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
  def title(state), do: to_string _get_cfg!(:title, nil).(state)

  @impl Views.Dialog
  @spec body(TUI.state) :: [Element.t]
  def body(state) do
    case _get_cfg!(:text, "").(state) do
      "" -> []
      txt -> [label(content: to_string(txt))]
    end
  end

  @impl Views.Dialog
  @spec buttons(TUI.state) :: [String.t | {String.t, keyword}]
  def buttons(state) do
    yes_no = [@button_no, @button_yes]
    if _get_cfg!(:show_cancel, false).(state),
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

    def yes, do: YesNo._get_cfg!(:yes, nil) >>> &(&1.())
    def no,  do: YesNo._get_cfg!(:no, fn -> @default_no end) >>> &(&1.())
  end

  @spec _get_cfg!(atom, term | nil) :: (TUI.state -> term | no_return)
  def _get_cfg!(key, default), do: fn state ->
    val = TUI.Overlay.find(state, @stateful_id).cfg[key]
    unless is_nil(val) do
      val
    else
      if is_nil(default),
         do: raise("Undefined #{key}"),
         else: default
    end
  end
end

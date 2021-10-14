defmodule DTask.TUI.Views.Dialog.Message do
  @moduledoc false

  alias DTask.TUI
  alias DTask.TUI.Views
  alias DTask.TUI.Views.Stateful

  import DTask.TUI.Views.Dialog.Util, only: [get_cfg!: 3]

  use Views.Dialog

  @stateful_id :message

  @impl Views.Dialog
  def stateful_id, do: @stateful_id

  @default_padding 10
  @button "[Enter] OK"

  @type cfg :: %{
                 required(:title)   => charlist | String.t,
                 optional(:text)    => charlist | String.t,
                 optional(:padding) => non_neg_integer | (TUI.state -> non_neg_integer)
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
  def buttons(state), do: [@button]

  defmodule React do
    alias DTask.TUI.Views.Dialog.YesNo

    @default_no :close_overlay

    use DTask.TUI.Util.Keys
    use Stateful.Reactive,
        bind: %{
          %{key: @enter} => {:external, [{:close, []}]},
        }

    @impl true
    def state_key, do: nil

    def close, do: fn _ -> :close_overlay end
  end

end

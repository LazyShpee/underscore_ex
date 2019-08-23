defmodule UnderscoreEx.Core.EventRegistry do
  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  def start_link(_opts \\ []) do
    Registry.start_link(keys: :duplicate, name: __MODULE__)
  end

  def subscribe() do
    # the calling process will be sent in
    Registry.register(__MODULE__, :subscribed, nil)
  end

  def unsubscribe(_mode \\ :kill)

  def unsubscribe(:nokill) do
    Registry.unregister(__MODULE__, :subscribed)
  end

  def unsubscribe(:kill) do
    Registry.unregister(__MODULE__, :subscribed)
    Process.exit(self(), :kill)
  end

  def dispatch(events) do
    Registry.dispatch(__MODULE__, :subscribed, fn entries ->
      Enum.each(entries, fn {pid, _} ->
        Enum.each(events, &send(pid, &1))
      end)
    end)
  end
end

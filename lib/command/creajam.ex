defmodule UnderscoreEx.Command.Creajam do
  @guild_id 684401012345536593
  @archive_cat_id 684412639736233998 # Submission channels moved here
  @submission_cat_id 684428853682241549 # New submission channels here
  @theme_chan_id 684402291834748949 # Theme posting channel
  @ping_role_id 684402967100522602 # Ping role for new themes
  @secret_chan_id 684415778090647618 # Used for testing, logs and stuff
  @secret_cat_id 684431368071282753 # Secret category id for tests
  def init do
    :erlcron.cron(:weekly_theme, {{:weekly, :mon, {0, :am}}, {UnderscoreEx.Command.Creajam, :new_theme, []}})
  end

  def new_theme do
    Nostrum.Api.create_guild_channel(684401012345536593, parent_id: @secret_cat_id, name: "Test Chan")
  end

  def archive_theme do

  end
end

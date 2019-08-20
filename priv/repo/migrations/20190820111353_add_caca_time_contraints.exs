defmodule UnderscoreEx.Repo.Migrations.AddCacaTimeContraints do
  use Ecto.Migration

  def change do
    create constraint(:caca_times, :start_before_end, check: "t_start <= t_end")
    # This one needs extension btree_gist
    create constraint(:caca_times, :no_overlapping_caca, exclude: ~s|gist (user_id WITH =, tsrange(t_start, t_end) WITH &&)|)
  end
end

defmodule UnderscoreEx.EctoType.Snowflake do
  @behaviour Ecto.Type
  def type, do: :string

  def cast(snowflake) when is_integer(snowflake), do: {:ok, Integer.to_string(snowflake)}

  def cast(snowflake) when is_binary(snowflake), do: {:ok, snowflake}

  def cast(_), do: :error

  def load(snowflake) when is_binary(snowflake) do
    {:ok, String.to_integer(snowflake)}
  end

  def dump(snowflake) when is_integer(snowflake) do
    {:ok, Integer.to_string(snowflake)}
  end

  def dump(snowflake) when is_binary(snowflake) do
    {:ok, snowflake}
  end

  def dump(_), do: :error

  def embed_as(_) do
    :dump
  end

  def equal?(term, term) do
    term == term
  end

end

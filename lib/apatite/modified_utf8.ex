defmodule Apatite.ModifiedUTF8 do
  def read(<<b::size(8), rest::binary>>, :boolean), do: {b != 0, rest}

  def read(<<b::size(8), rest::binary>>, :unsigned_byte), do: {b, rest}

  def read(<<s::size(16), rest::binary>>, :unsigned_short), do: {s, rest}

  def read(<<i::size(32), rest::binary>>, :unsigned_int), do: {i, rest}

  def read(<<l::size(64), rest::binary>>, :unsigned_long), do: {l, rest}

  def read(data, :utf) do
    {len, rest} = data |> read(:unsigned_short)
    rest |> read_utf(len)
  end

  def read(data, :nullable_utf) do
    {has_content, data} = data |> read(:boolean)

    case has_content do
      false -> {nil, data}
      true -> read(data, :utf)
    end
  end

  defp read_utf(_data, acc \\ <<>>, _bytes)
  defp read_utf(data, acc, 0), do: {acc, data}

  defp read_utf(<<0::size(1), n::size(7), rest::binary>>, acc, bytes) do
    read_utf(rest, acc <> <<n>>, bytes - 1)
  end

  defp read_utf(
        <<0b110::size(3), a::size(5), 0b10::size(2), b::size(6), rest::binary>>,
        acc,
        bytes
      ) do
    read_utf(rest, acc <> <<0b110::size(3), a::size(5), 0b10::size(2), b::size(6)>>, bytes - 2)
  end

  defp read_utf(
        <<0b1110::size(4), a::size(4), 0b10::size(2), b::size(6), 0b10::size(2), c::size(6),
          rest::binary>>,
        acc,
        bytes
      ) do
    read_utf(rest, acc <> <<0b1110::size(4), a::size(4), 0b10::size(2), b::size(6), 0b10::size(2), c::size(6)>>, bytes - 3)
  end

  def read_all(_data, _acc \\ [], _types)
  def read_all(data, acc, []), do: {acc |> Enum.reverse(), data}

  def read_all(data, acc, [type | types]) do
    {result, rest} = data |> read(type)
    read_all(rest, [result | acc], types)
  end

  def write(data, value, :boolean), do: data <> <<if(value == true, do: 1, else: 0)::size(8)>>

  def write(data, value, :unsigned_byte), do: data <> <<value::size(8)>>

  def write(data, value, :unsigned_short), do: data <> <<value::size(16)>>

  def write(data, value, :unsigned_int), do: data <> <<value::size(32)>>

  def write(data, value, :unsigned_long), do: data <> <<value::size(64)>>

  def write(data, value, :utf) do
    value
    |> String.codepoints()
    |> Enum.reduce(data |> write(byte_size(value), :unsigned_short), fn
      chars, data -> data <> chars
    end)
  end

  def write(data, value, :nullable_utf) when value in [nil, ""] do
    data
    |> write(false, :boolean)
  end

  def write(data, value, :nullable_utf) do
    data
    |> write(true, :boolean)
    |> write(value, :utf)
  end
end

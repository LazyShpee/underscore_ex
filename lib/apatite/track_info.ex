defmodule Apatite.TrackInfo do
  defstruct flags: 0,

            # Int
            # Byte
            version: 0,
            # UTF
            title: "",
            # UTF
            author: "",
            # Long
            length: 0,
            # UTF
            identifier: "",
            # Boolean
            is_stream: false,
            # Nullable UTF text
            uri: nil,
            # UTF
            source: "",
            # Long
            position: 0

  alias Apatite.ModifiedUTF8
  import Bitwise

  def decode(track) do
    data = track |> Base.decode64!()
    {flags, data} = data |> ModifiedUTF8.read(:unsigned_int)

    {version, data} =
      case (flags &&& 0b1) != 0 do
        true -> data |> ModifiedUTF8.read(:unsigned_byte)
        false -> {1, data}
      end

    {title, data} = data |> ModifiedUTF8.read(:utf)
    {author, data} = data |> ModifiedUTF8.read(:utf)
    {length, data} = data |> ModifiedUTF8.read(:unsigned_long)
    {identifier, data} = data |> ModifiedUTF8.read(:utf)
    {is_stream, data} = data |> ModifiedUTF8.read(:boolean)
    {uri, data} = data |> ModifiedUTF8.read(:nullable_utf)
    {source, data} = data |> ModifiedUTF8.read(:utf)
    {position, ""} = data |> ModifiedUTF8.read(:unsigned_long)

    %__MODULE__{
      flags: (flags &&& 0xC0000000) >>> 30,
      version: version,
      title: title,
      author: author,
      length: length,
      identifier: identifier,
      is_stream: is_stream,
      uri: uri,
      source: source,
      position: position
    }
  end

  def encode(%__MODULE__{version: 2} = _track) do
  end
end

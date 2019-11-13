defmodule UnderscoreEx.Util.File do
  def signature("\x89\x50\x4E\x47\x0D\x0A\x1A\x0A" <> _), do: {:ok, "png"}

  def signature("GIF87a" <> _), do: {:ok, "gif"}
  def signature("GIF89a" <> _), do: {:ok, "gif"}

  def signature("\xFF\xD8\xFF\xDB" <> _), do: {:ok, "jpg"}
  def signature("\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46\x00\x01" <> _), do: {:ok, "jpg"}
  def signature("\xFF\xD8\xFF\xEE" <> _), do: {:ok, "jpg"}

  def signature(
        <<"\xFF\xD8\xFF\xE1", _::binary-size(16), "\x45\x78\x69\x66\x00\x00", _::binary>>
      ),
      do: {:ok, "jpg"}

  def signature("\x42\x4D" <> _), do: {:ok, "bmp"}

  def signature("\x1A\x45\xDF\xA3" <> _), do: {:ok, "webm"}

  def signature("\x25\x50\x44\x46\x2d" <> _), do: {:ok, "pdf"}

  def signature(_), do: {:error, :unknown}
end

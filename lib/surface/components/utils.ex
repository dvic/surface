defmodule Surface.Components.Utils do
  @moduledoc false
  import Surface, only: [event_to_opts: 2]

  @valid_uri_schemes [
    "http:",
    "https:",
    "ftp:",
    "ftps:",
    "mailto:",
    "news:",
    "irc:",
    "gopher:",
    "nntp:",
    "feed:",
    "telnet:",
    "mms:",
    "rtsp:",
    "svn:",
    "tel:",
    "fax:",
    "xmpp:"
  ]

  def valid_destination!(%URI{} = uri, context) do
    valid_destination!(URI.to_string(uri), context)
  end

  def valid_destination!({:safe, to}, context) do
    {:safe, valid_string_destination!(IO.iodata_to_binary(to), context)}
  end

  def valid_destination!({other, to}, _context) when is_atom(other) do
    [Atom.to_string(other), ?:, to]
  end

  def valid_destination!(to, context) do
    valid_string_destination!(IO.iodata_to_binary(to), context)
  end

  for scheme <- @valid_uri_schemes do
    def valid_string_destination!(unquote(scheme) <> _ = string, _context), do: string
  end

  def valid_string_destination!(to, context) do
    if not match?("/" <> _, to) and String.contains?(to, ":") do
      raise ArgumentError, """
      unsupported scheme given to #{context}. In case you want to link to an
      unknown or unsafe scheme, such as javascript, use a tuple: {:javascript, rest}
      """
    else
      to
    end
  end

  def csrf_data(to, opts) do
    case Keyword.pop(opts, :csrf_token, true) do
      {csrf, opts} when is_binary(csrf) ->
        {[csrf: csrf], opts}

      {true, opts} ->
        {[csrf: csrf_token(to)], opts}

      {false, opts} ->
        {[], opts}
    end
  end

  defp csrf_token(to) do
    {mod, fun, args} = Application.fetch_env!(:surface, :csrf_token_reader)
    apply(mod, fun, [to | args])
  end

  def skip_csrf(opts) do
    Keyword.delete(opts, :csrf_token)
  end

  def opts_to_attrs(opts) do
    for {key, value} <- opts do
      case key do
        :phx_blur -> {:"phx-blur", value}
        :phx_focus -> {:"phx-focus", value}
        :phx_capture_click -> {:"phx-capture-click", value}
        :phx_keydown -> {:"phx-keydown", value}
        :phx_keyup -> {:"phx-keyup", value}
        :phx_target -> {:"phx-target", value}
        :data -> data_to_attrs(value)
        _ -> {key, value}
      end
    end
    |> List.flatten()
  end

  defp data_to_attrs(data) when is_list(data) do
    for {key, value} <- data do
      {:"data-#{key}", value}
    end
  end

  def events_to_opts(assigns) do
    [
      event_to_opts(assigns.blur, :phx_blur),
      event_to_opts(assigns.focus, :phx_focus),
      event_to_opts(assigns.capture_click, :phx_capture_click),
      event_to_opts(assigns.keydown, :phx_keydown),
      event_to_opts(assigns.keyup, :phx_keyup)
    ]
    |> List.flatten()
  end
end

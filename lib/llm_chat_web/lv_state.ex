defmodule LlmChatWeb.LvState do
  @moduledoc false
  alias LlmChat.Contexts.{Chat, Conversation, LlmPreset, User, Suggestion}

  def index(user_email) do
    suggestions = Suggestion.get_default()
    suggestion = Enum.random(suggestions)
    index(user_email, %{suggestions: suggestions, uistate: uistate(suggestion)})
  end

  def index(user_email, chat_id) when is_binary(chat_id) do
    index(user_email, chat_id, Conversation.current_path(chat_id))
  end

  def index(user_email, %{} = main) do
    %{
      main: main |> Map.put(:lvstate, lvstate()),
      sidebar: sidebar(user_email),
      sidebar_open: true,
      user: User.get_by_email(user_email)
    }
  end

  def index(user_email, chat_id, ui_path) when is_binary(chat_id) do
    main = Chat.details(chat_id, ui_path)
    index(user_email, main |> Map.put(:uistate, uistate("")))
  end

  def sidebar(user_email) do
    if is_nil(user_email), do: %{periods: []}, else: %{periods: Chat.list_by_period(user_email)}
  end

  defp uistate(suggestion) do
    presets = LlmPreset.list()
    default_preset = LlmPreset.default()
    uistate(suggestion, presets, default_preset)
  end

  defp uistate(suggestion, presets, sel_preset) do
    %{
      suggestion: suggestion,
      presets: presets,
      sel_preset: sel_preset
    }
  end

  defp lvstate() do
    %{}
  end

  def finish_streaming(main) do
    main |> with_api_call() |> with_streaming() |> with_edit()
  end

  def with_chunk(streaming, chunk) do
    assistant = streaming.assistant
    content = assistant.content
    %{streaming | assistant: %{assistant | content: content <> chunk}}
  end

  def with_streaming(main, streaming \\ nil) do
    if is_nil(streaming) do
      %{main | uistate: main.uistate |> Map.delete(:streaming)}
    else
      %{main | uistate: main.uistate |> Map.put(:streaming, streaming)}
    end
  end

  def with_cancel_pid(main, pid) do
    %{main | uistate: %{main.uistate | streaming: %{main.uistate.streaming | cancel_pid: pid}}}
  end

  def with_edit(main, edit_msg_id \\ "") do
    if edit_msg_id == "" do
      %{main | uistate: main.uistate |> Map.delete(:edit_msg_id)}
    else
      %{main | uistate: main.uistate |> Map.put(:edit_msg_id, edit_msg_id)}
    end
  end

  def with_selected_preset(main, preset) do
    %{main | uistate: %{main.uistate | sel_preset: preset}}
  end

  def with_ui_path(main, ui_path) do
    main |> Map.merge(Chat.details(main.chat.id, ui_path))
  end

  def with_api_call(main, api_call \\ nil) do
    if is_nil(api_call) do
      %{main | lvstate: main.lvstate |> Map.delete(:api_call)}
    else
      %{main | lvstate: main.lvstate |> Map.put(:api_call, api_call)}
    end
  end
end

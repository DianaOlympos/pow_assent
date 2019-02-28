defmodule PowAssent.Strategy.VK do
  @moduledoc """
  VK.com OAuth 2.0 strategy.

  ## Usage

      config :my_app, :pow_assent,
        providers: [
          vk: [
            client_id: "REPLACE_WITH_CLIENT_ID",
            client_secret: "REPLACE_WITH_CLIENT_SECRET",
            strategy: PowAssent.Strategy.VK
          ]
        ]
  """
  use PowAssent.Strategy.OAuth2.Base

  alias PowAssent.Strategy.OAuth2

  @profile_fields ["uid", "first_name", "last_name", "photo_200", "screen_name", "verified"]
  @url_params     [fields: Enum.join(@profile_fields, ","), v: "5.69", https: "1"]

  @spec default_config(Keyword.t()) :: Keyword.t()
  def default_config(config) do
    params          = Keyword.get(config, :user_url_params, [])
    user_url_params = Keyword.merge(@url_params, params)

    [
      site: "https://api.vk.com",
      authorize_url: "https://oauth.vk.com/authorize",
      token_url: "https://oauth.vk.com/access_token",
      user_url: "/method/users.get",
      authorization_params: [scope: "email"],
      user_url_params: user_url_params
    ]
  end

  @spec normalize(Keyword.t(), map()) :: {:ok, map()}
  def normalize(_config, user) do
    {:ok, %{
      "uid"        => to_string(user["id"]),
      "nickname"   => user["screen_name"],
      "first_name" => user["first_name"],
      "last_name"  => user["last_name"],
      "name"       => Enum.join([user["first_name"], user["last_name"]], " "),
      "email"      => user["email"],
      "image"      => user["photo_200"],
      "verified"   => user["verified"] > 0}}
  end

  @spec get_user(Keyword.t(), map()) :: {:ok, map()} | {:error, term()}
  def get_user(config, token) do
    params =
      config
      |> Keyword.get(:user_url_params, [])
      |> Keyword.put(:access_token, token["access_token"])

    config
    |> OAuth2.get_user(token, params)
    |> handle_user_response(token)
  end

  defp handle_user_response({:ok, %{"response" => [user]}}, token) do
    user  = Map.put_new(user, "email", get_email(token))

    {:ok, user}
  end
  defp handle_user_response({:ok, user}, _token),
    do: {:error, %PowAssent.RequestError{message: "Retrieved invalid response: #{inspect user}"}}
  defp handle_user_response({:error, error}, _token),
    do: {:error, error}

  defp get_email(%{"email" => email}), do: email
  defp get_email(_any), do: nil
end

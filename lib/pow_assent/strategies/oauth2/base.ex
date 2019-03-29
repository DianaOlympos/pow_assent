defmodule PowAssent.Strategy.OAuth2.Base do
  @moduledoc """
  OAuth 2.0 strategy base.

  ## Usage

      defmodule MyApp.MyOAuth2Strategy do
        use PowAssent.Strategy.OAuth2.Base

        def default_config(_config) do
          [
            site: "https://api.example.com",
            user_url: "/authorization.json"
          ]
        end

        def normalize(_config, user) do
          %{
            "uid"   => user["id"],
            "name"  => user["name"],
            "email" => user["email"]
          }
        end
      end
  """
  alias PowAssent.Strategy, as: Helpers
  alias PowAssent.Strategy.OAuth2

  @callback default_config(Keyword.t()) :: Keyword.t()
  @callback normalize(Keyword.t(), map()) :: {:ok, map()} | {:error, term()}
  @callback get_user(Keyword.t(), map()) :: {:ok, map()} | {:error, term()}

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      alias PowAssent.Strategy, as: Helpers

      def authorize_url(config), do: unquote(__MODULE__).authorize_url(config, __MODULE__)

      def callback(config, params), do: unquote(__MODULE__).callback(config, params, __MODULE__)

      def get_user(config, token), do: OAuth2.get_user(config, token)

      defoverridable unquote(__MODULE__)
    end
  end

  @spec authorize_url(Keyword.t(), module()) :: {:ok, %{session_params: %{state: binary()}, url: binary()}}
  def authorize_url(config, strategy) do
    config
    |> set_config(strategy)
    |> OAuth2.authorize_url()
  end

  @spec callback(Keyword.t(), map(), module()) :: {:ok, %{user: map()}} | {:error, term()}
  def callback(config, params, strategy) do
    config = set_config(config, strategy)

    config
    |> OAuth2.callback(params, strategy)
    |> normalize(config, strategy)
  end

  defp normalize({:ok, %{user: user} = results}, config, strategy) do
    case strategy.normalize(config, user) do
      {:ok, user}     -> {:ok, %{results | user: Helpers.prune(user)}}
      {:error, error} -> normalize({:error, error}, config, strategy)
    end
  end
  defp normalize({:error, error}, _config, _strategy), do: {:error, error}

  defp set_config(config, strategy) do
    config
    |> strategy.default_config()
    |> Keyword.merge(config)
    |> Keyword.put(:strategy, strategy)
  end
end

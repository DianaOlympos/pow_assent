defmodule PowAssent do
  @moduledoc false

  defmodule CallbackError do
    defexception [:message, :error, :error_uri]
  end

  defmodule CallbackCSRFError do
    defexception message: "CSRF detected"
  end

  defmodule RequestError do
    defexception [:message, :error]

    alias PowAssent.HTTPResponse

    @spec unexpected(HTTPResponse.t()) :: %__MODULE__{}
    def unexpected(response) do
      %__MODULE__{
        message:
          """
          An unexpected success response was received:

          #{inspect response.body}
          """,
        error: :unexpected_response
      }
    end

    @spec invalid(HTTPResponse.t()) :: %__MODULE__{}
    def invalid(response) do
      %__MODULE__{
        message:
          """
          Server responded with status: #{response.status}

          Headers:#{Enum.reduce(response.headers, "", fn {k, v}, acc -> acc <> "\n#{k}: #{v}" end)}

          Body:
          #{inspect response.body}
          """,
        error: :invalid_server_response
      }
    end
  end

  defmodule ConfigurationError do
    defexception [:message]
  end
end

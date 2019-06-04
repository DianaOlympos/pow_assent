defmodule PowAssent.Strategy.BasecampTest do
  use PowAssent.Test.OAuth2TestCase

  alias PowAssent.Strategy.Basecamp

  @accounts_response [
    %{
      "product" => "bc3",
      "id" => 99_999_999,
      "name" => "Honcho Design",
      "href" => "https://3.basecampapi.com/99999999",
      "app_href" => "https://3.basecamp.com/99999999"
    },
    %{
      "product" => "bcx",
      "id" => 88_888_888,
      "name" => "Wayne Enterprises, Ltd.",
      "href" => "https://basecamp.com/88888888/api/v1",
      "app_href" => "https://basecamp.com/88888888"
    },
    %{
      "product" => "campfire",
      "id" => 44_444_444,
      "name" => "Acme Shipping Co.",
      "href" => "https://acme4444444.campfirenow.com",
      "app_href" => "https://acme4444444.campfirenow.com"
    }
  ]
  @user_response %{
    "expires_at" => "2012-03-22T16:56:48-05:00",
    "identity" => %{
      "id" => 9_999_999,
      "first_name" => "Jason",
      "last_name" => "Fried",
      "email_address" => "jason@basecamp.com"
    },
    "accounts" => @accounts_response
  }
  @user %{
    "email" => "jason@basecamp.com",
    "name" => "Jason Fried",
    "first_name" => "Jason",
    "last_name" => "Fried",
    "accounts" => @accounts_response,
    "uid" => 9_999_999
  }

  test "authorize_url/2", %{config: config} do
    assert {:ok, %{url: url}} = Basecamp.authorize_url(config)
    assert url =~ "/authorization/new"
    assert url =~ "type=web_server"
  end

  test "callback/2", %{config: config, callback_params: params, bypass: bypass} do
    expect_oauth2_access_token_request(bypass, uri: "/authorization/token")
    expect_oauth2_user_request(bypass, @user_response, uri: "/authorization.json")

    assert {:ok, %{user: user}} = Basecamp.callback(config, params)
    assert user == @user
  end
end

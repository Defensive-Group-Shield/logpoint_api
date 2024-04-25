defmodule LogpointApi do
  @moduledoc """
  Documentation for `LogpointApi`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> LogpointApi.hello()
      :world

  """
  def hello do
    :world
  end
end

defmodule LogpointApi.SearchApi do
  @allowed_types ["user_preference", "loginspects", "Logpoint_repos", "devices", "livesearches"]

  defmodule Query do
    @derive {Jason.Encoder, only: [:query, :time_range, :limit, :repos]}
    defstruct [:query, :time_range, :limit, :repos]
  end

  defmodule SearchID do
    @derive {Jason.Encoder, only: [:search_id]}
    defstruct [:search_id]
  end

  def get_user_timezone(ip, username, secret_key),
    do: get_allowed_data(ip, username, secret_key, "user_preference")

  def get_logpoints(ip, username, secret_key),
    do: get_allowed_data(ip, username, secret_key, "loginspects")

  def get_repos(ip, username, secret_key),
    do: get_allowed_data(ip, username, secret_key, "Logpoint_repos")

  def get_devices(ip, username, secret_key),
    do: get_allowed_data(ip, username, secret_key, "devices")

  def get_livesearches(ip, username, secret_key),
    do: get_allowed_data(ip, username, secret_key, "livesearches")

  def get_search_id(ip, username, secret, %Query{} = request_data),
    do: get_search_logs(ip, username, secret, request_data)

  def get_search_result(ip, username, secret, %SearchID{} = request_data),
    do: get_search_logs(ip, username, secret, request_data)

  defp make_request(ip, path, payload) do
    url = "https://" <> ip <> path
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    # On-prem uses self signed certificates and we thus need to disable the verification.
    options = [ssl: [{:verify, :verify_none}]]

    case HTTPoison.post(url, payload, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        IO.puts("Received response with status code #{status_code}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("HTTP request failed with reason: #{reason}")
    end
  end

  defp get_allowed_data(ip, username, secret_key, type) when type in @allowed_types do
    payload =
      URI.encode_query(%{
        "username" => username,
        "secret_key" => secret_key,
        "type" => type
      })

    make_request(ip, "/getalloweddata", payload)
  end

  defp get_search_logs(ip, username, secret_key, request_data) do
    payload =
      URI.encode_query(%{
        "username" => username,
        "secret_key" => secret_key,
        "requestData" => request_data |> Jason.encode!()
      })

    make_request(ip, "/getsearchlogs", payload)
  end
end

defmodule LogpointApi.IncidentApi do
  defp make_request(ip, path, params) do
    url = "https://" <> ip <> path
    headers = [{"Content-Type", "application/json"}]
    body = Jason.encode!(params)
    # On-prem uses self signed certificates and we thus need to disable the verification.
    options = [ssl: [{:verify, :verify_none}]]

    case HTTPoison.request(:get, url, body, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        IO.puts("Received response with status code #{status_code}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("HTTP request failed with reason: #{reason}")
    end
  end
end

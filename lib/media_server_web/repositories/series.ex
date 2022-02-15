defmodule MediaServerWeb.Repositories.Series do

  def get_url(url) do
    "#{ System.get_env("SONARR_BASE_URL") }/api/v3/#{ url }?apiKey=#{ System.get_env("SONARR_API_KEY") }"
  end

  def get_latest(amount) do

    case get_url("series") do

      nil -> []

      _ ->
        case HTTPoison.get(get_url("series")) do

          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

            Enum.sort_by(Jason.decode!(body), &(&1["added"]), :desc)
            |> Enum.filter(fn x -> x["statistics"]["episodeFileCount"] !== 0 end)
            |> Enum.take(amount)
        end
    end
  end

  def get_all() do

    case HTTPoison.get(get_url("series")) do

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->

        Enum.sort_by(Jason.decode!(body), &(&1["title"]), :asc)
        |> Enum.filter(fn x -> x["statistics"]["episodeFileCount"] !== 0 end)
    end
  end

  def get_serie(id) do

    case HTTPoison.get(get_url("series/#{ id }")) do

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode!(body)
    end
  end

  def get_episodes(series_id) do

    case HTTPoison.get("#{ get_url("episode") }&seriesId=#{ series_id }") do

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Enum.filter(Jason.decode!(body), fn x -> x["hasFile"] end)
        |> add_images_to_episodes()
    end
  end

  def get_episode(id) do

    case HTTPoison.get("#{ get_url("episode/#{ id }") }") do

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode!(body)
    end
  end

  def get_episode_path(id) do

    case HTTPoison.get("#{ get_url("episode/#{ id }") }") do

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode!(body)["episodeFile"]["path"]
    end
  end

  def add_images_to_episodes(episodes) do
    Enum.map(episodes, fn episode ->
      Map.put(episode, "images", Map.get(get_episode(episode["id"]), "images"))
    end)
  end
end
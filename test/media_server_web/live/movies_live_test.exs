defmodule MediaServerWeb.MoviesLiveTest do
  use MediaServerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias MediaServer.AccountsFixtures
  alias MediaServerWeb.Repositories.Movies

  setup %{conn: conn} do
    user = AccountsFixtures.user_fixture()

    %{conn: conn |> log_in_user(user), user: user}
  end

  test "it should render index", %{conn: conn} do
    {:ok, _view, disconnected_html} = live(conn, Routes.movies_index_path(conn, :index))

    assert disconnected_html =~ "Caminandes: Llama Drama"
    assert disconnected_html =~ "Caminandes: Gran Dillama"
    assert disconnected_html =~ "Caminandes:  Llamigos"
  end

  test "it should render index paged", %{conn: conn} do
    {:ok, _view, disconnected_html} =
      live(conn, Routes.movies_index_path(conn, :index, page: "1"))

    assert disconnected_html =~ "Caminandes: Llama Drama"
    assert disconnected_html =~ "Caminandes: Gran Dillama"
    assert disconnected_html =~ "Caminandes:  Llamigos"
  end

  test "it should render show", %{conn: conn} do
    movie = MediaServer.MoviesIndex.get_movie("1")
    cast = Movies.get_cast(movie["id"])

    {:ok, view, _disconnected_html} = live(conn, Routes.movies_show_path(conn, :show, movie["id"]))

    send(view.pid, {:cast, cast})
  end

  test "it should add to playlist", %{conn: conn, user: user} do
    movie = MediaServer.MoviesIndex.get_all() |> List.first()
    cast = Movies.get_cast(movie["id"])

    {:ok, playlist} = MediaServer.Playlists.create(%{name: "some playlist", user_id: user.id})

    {:ok, view, _disconnected_html} =
      live(conn, Routes.movies_show_path(conn, :show, movie["id"]))

    send(view.pid, {:cast, cast})

    view
    |> form("#playlists-form", playlists: %{"#{ playlist.id }" => "true"})
    |> render_change()

    playlist_movie = MediaServer.PlaylistMedia.all() |> List.first()

    assert playlist_movie.media_id === movie["id"]

    {:ok, _view, disconnected_html} =
      live(conn, Routes.playlist_show_path(conn, :show, playlist.id))

    assert disconnected_html =~ Routes.movies_show_path(conn, :show, movie["id"])
  end

  test "it should delete from playlist", %{conn: conn, user: user} do
    movie = MediaServer.MoviesIndex.get_all() |> List.first()
    cast = Movies.get_cast(movie["id"])
    {:ok, some_playlist} = MediaServer.Playlists.create(%{name: "some playlist", user_id: user.id})
    {:ok, another_playlist} = MediaServer.Playlists.create(%{name: "another playlist", user_id: user.id})

    {:ok, view, _disconnected_html} =
      live(conn, Routes.movies_show_path(conn, :show, movie["id"]))

    send(view.pid, {:cast, cast})

    view
    |> form("#playlists-form", playlists: %{"#{ some_playlist.id }" => "true", "#{ another_playlist.id }" => "true"})
    |> render_change()

    assert Enum.count(MediaServer.PlaylistMedia.all()) === 2

    view
    |> form("#playlists-form", playlists: %{"#{ some_playlist.id }" => "false", "#{ another_playlist.id }" => "true"})
    |> render_change()

    assert Enum.count(MediaServer.PlaylistMedia.all()) === 1
  end

  test "it should watch", %{conn: conn} do
    movie = MediaServer.MoviesIndex.get_all() |> List.first()
    cast = Movies.get_cast(movie["id"])

    {:ok, view, _html} = live(conn, Routes.movies_show_path(conn, :show, movie["id"]))

    send(view.pid, {:cast, cast})

    assert view |> element("#play-#{movie["id"]}", "Watch") |> render_click()
  end
end

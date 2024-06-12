defmodule MediaServer.Series do
  use Ecto.Schema
  import Ecto.Changeset

  schema "series" do
    field :external_id, :integer

    timestamps()
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:external_id])
    |> validate_required([:external_id])
  end

  def insert(attrs) do
    changeset = changeset(attrs)

    case MediaServer.Repo.insert(changeset, on_conflict: :nothing, conflict_target: [:external_id]) do
      {:ok, record} ->

        MediaServer.AddEpisode.new(%{"items" => MediaServerWeb.Repositories.Episodes.for_db(record.external_id, record.id)})
        |> Oban.insert()

        {:ok, record}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end

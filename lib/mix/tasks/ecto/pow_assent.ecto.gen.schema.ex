defmodule Mix.Tasks.PowAssent.Ecto.Gen.Schema do
  @shortdoc "Generates user identity schema"

  @moduledoc """
  Generates a user identity schema.

      mix pow_assent.ecto.gen.schema -r MyApp.Repo

      mix pow_assent.ecto.gen.schema -r MyApp.Repo CustomUserIdentity custom_user_identity
  """
  use Mix.Task

  alias PowAssent.Ecto.UserIdentities.Schema.Module, as: SchemaModule
  alias Mix.{Generator, Pow}

  @switches [context_app: :string, binary_id: :boolean]
  @default_opts [binary_id: false]

  @doc false
  def run(args) do
    Pow.no_umbrella!("pow_assent.ecto.gen.schema")

    args
    |> Pow.parse_options(@switches, @default_opts)
    |> parse()
    |> create_schema_file()
  end

  defp parse({config, parsed, _invalid}) do
    case parsed do
      [schema_name, schema_plural | _rest] ->
        Map.merge(config, %{schema_name: schema_name, schema_plural: schema_plural})

      _ ->
        config
    end
  end

  defp create_schema_file(%{binary_id: binary_id} = config) do
    context_app   = Map.get(config, :context_app, Pow.context_app())
    context_base  = Pow.context_base(context_app)
    schema_name   = Map.get(config, :schema_name, "UserIdentities.UserIdentity")
    schema_plural = Map.get(config, :schema_plural, "user_identities")
    schema        = SchemaModule.new(context_base, schema_name, schema_plural, binary_id: binary_id)
    content       = SchemaModule.gen(schema)
    dir_name     =
      schema.schema_name
      |> String.split(".")
      |> Enum.slice(0..-2)
      |> Enum.join(".")
      |> Macro.underscore()
    file_name    =
      schema.module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()
      |> Kernel.<>(".ex")

    context_app
    |> Pow.context_lib_path(dir_name)
    |> maybe_create_directory()
    |> Path.join(file_name)
    |> ensure_unique()
    |> Generator.create_file(content)
  end

  defp maybe_create_directory(path) do
    Generator.create_directory(path)

    path
  end

  defp ensure_unique(path) do
    path
    |> File.exists?()
    |> case do
      false -> path
      _     -> Mix.raise("schema file can't be created, there is already a schema file in #{path}.")
    end
  end
end

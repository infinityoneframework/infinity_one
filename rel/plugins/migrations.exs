defmodule InfinityOne.MigrationsPlugin do
  use Mix.Releases.Plugin

  @migrations_path Path.join(~w(priv repo migrations))

  defp get_plugins do
    Path.wildcard("./plugins/*")
  end

  defp get_migration_paths do
    Enum.filter(get_plugins(), fn path ->
      path
      |> Path.join(@migrations_path)
      |> File.exists?()
    end)
  end

  # defp ls_migrations(release) do
  #   path = Path.join([release.output_dir, "lib", "#{release.name}-#{release.version}" | ~w(priv repo migrations)])
  #   info inspect(File.ls(path))
  # end

  defp migrations_path(release) do
    Path.join([release.output_dir, "lib", "#{release.name}-#{release.version}", @migrations_path])
  end

  def copy_migrations!(release) do
    path = migrations_path(release)

    Enum.each get_migration_paths(), fn plugin_path ->
      File.cp_r! Path.join(plugin_path, @migrations_path), path
    end
  end

  def before_assembly(%Release{} = release, _opts) do
    # info "This is executed just prior to assembling the release"
    # info inspect(release)
    release # or nil
  end

  def after_assembly(%Release{} = release, _opts) do
    # info "This is executed just after assembling, and just prior to packaging the release"
    # info inspect(File.ls(release.output_dir))
    copy_migrations!(release)
    # info inspect(release)
    release # or nil
  end

  def before_package(%Release{} = release, _opts) do
    # info "This is executed just before packaging the release"
    # info inspect(release)
    release # or nil
  end

  def after_package(%Release{} = release, _opts) do
    # info "This is executed just after packaging the release"
    release # or nil
  end

  def after_cleanup(_args, _opts) do
    # info "This is executed just after running cleanup"
    :ok # It doesn't matter what we return here
  end
end

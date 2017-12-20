# Copyright (C) E-MetroTel, 2015 - 2018 - All Rights Reserved
# This software contains material which is proprietary and confidential
# to E-MetroTel and is made available solely pursuant to the terms of
# a written license agreement with E-MetroTel.

defmodule Mix.Tasks.Rpm.Prepare do
  @moduledoc """
  Prepare for building an rpm

  Creates and copies the SOURCES and SPEC files.


  ## Examples

    # Copies the files
    mix rpm.prepare

    # Build the rpm
    rpmbuild -bb ~/rpmbuild/SPECS/ucx_ucc.spec

    # Use a different rpmbuild directory
    mix rpm.prepare --topdir=/home/myuser/mybuild

    # Copy and build
    mix rpm.prepare --build


  """
  @shortdoc "Create and copy files for rpmbuild"

  use     Mix.Task

  defmodule Config do
    defstruct topdir: nil, name: nil, version: nil, verbosity: "debug",
              exportdir: nil, build: false, spec_path: "", build_opts: ""
  end

  def run(args) do
    do_run(args)
  end

  def do_run(args) do
    config =
    parse_args(args)
    config
    |> do_prepare
    info "The rpmbuild files for #{config.name}-#{config.version} have been created."
  end

  def do_prepare(%Config{name: app, version: version, exportdir: exportdir} = config) do
    debug "Preparing files for #{app}-#{version}..."
    File.mkdir_p exportdir
    File.rm_rf Path.join(exportdir, app)
    check_spec_version(config)
    |> export_source
    |> copy_migration_files
    |> create_tar_file
    |> copy_spec_file
    |> build_rpm
  end

  defp check_spec_version(%Config{name: _name, version: _version} = config) do
    debug "TODO: implement checking the spec file version, and replace it if necessary"
    config
  end

  defp export_source(%Config{exportdir: exportdir, name: app} = config) do
    export_path = Path.join(exportdir, app)
    clone_source(".", Path.join(exportdir, app))
    clone_source("./plugins/mscs", Path.join(export_path, "plugins/mscs"))
    clone_source("./plugins/ucx_presence", Path.join(export_path, "plugins/ucx_presence"))
    clone_source("./plugins/ucx_adapter", Path.join(export_path, "plugins/ucx_adapter"))
    File.cp_r! "./priv/static", Path.join([exportdir, app | ~w(priv static)])
    config
  end

  defp clone_source(src, dst) do
    IO.puts "src #{src} dst #{dst}"
    :os.cmd 'git clone #{src} #{dst}'
    dst
    |> Path.join(".git")
    |> File.rm_rf!
  end

  defp copy_source(path, plugin) do
    File.cp_r! Path.join("./plugins/", Path.join(plugin, "/priv/repo/migrations")), Path.join(path, "priv/repo/migrations")
  end

  defp copy_migration_files(%Config{exportdir: exportdir, name: app} = config) do
  	path = Path.join(exportdir, app)
    copy_source(path, "mscs")
    copy_source(path, "ucc_chat")
    copy_source(path, "ucc_webrtc")
    copy_source(path, "ucc_settings")
    copy_source(path, "ucx_presence")
    config
  end

  defp create_tar_file(%Config{topdir: topdir, name: app, exportdir: exportdir} = config) do
    tar_file = Path.join([topdir, "SOURCES", source_file_name(config)])
    File.mkdir_p Path.join [topdir, "SOURCES"]
    :os.cmd 'tar czf #{tar_file} -C #{exportdir} #{app}'
    info "sources tar created in #{exportdir}"
    config
  end

  defp source_file_name(%Config{name: name, version: version}) do
    "#{name}-#{version}.tgz"
  end

  defp copy_spec_file(%Config{name: name, topdir: topdir} = config) do
    spec_file = Path.join(["rpm", "SPECS", "#{name}.spec"])
    dest_path = Path.join [topdir, "SPECS", "#{name}.spec"]
    File.mkdir_p Path.join [topdir, "SPECS"]
    File.cp! spec_file, dest_path
    info "spec file copied to #{dest_path}"
    %Config{config | spec_path: dest_path}
  end

  defp build_rpm(%Config{build: true, spec_path: spec_path, build_opts: build_opts} = config) do
    rpmbuild = "rpmbuild #{inspect build_opts} #{spec_path}"
    info "Building RPM with #{rpmbuild}. This may take a while..."
    case System.cmd "rpmbuild", build_opts ++ [spec_path] do
      {res, 0} ->
        case Regex.scan(~r/Wrote: ([^\n]+)/, res) do
          [[_, rpm_path]] ->
            info "The rpm can be found here: #{rpm_path}"
            info "To sign the rpm, run the following command:"
            IO.puts "rpm --resign #{rpm_path}"
          _ ->
            error "Could not find the output file"
        end
      {_res, rc} ->
        error "rpmbuild rc: #{rc}"
    end
    config
  end
  defp build_rpm(config), do: config

  defp parse_args(argv) do
    {args, _, _} = _res = OptionParser.parse(argv)
    defaults = %Config{
      name:    Mix.Project.config |> Keyword.get(:app) |> Atom.to_string,
      version: Mix.Project.config |> Keyword.get(:version),
      topdir:  Path.join(System.user_home, "rpmbuild"),
      exportdir: Path.join(System.user_home, "export"),
      build_opts: ["-bb"]
    }
    Enum.reduce args, defaults, fn arg, config ->
      case arg do
        {:verbosity, verbosity} ->
          %Config{config | verbosity: String.to_atom(verbosity)}
        {:buildopts, opts} ->
          %Config{config | build_opts: String.split(opts, " ", trim: true)}
        {key, value} ->
          Map.put(config, key, value)
      end
    end
  end
  @doc "Print an informational message without color"
  def debug(message), do: IO.puts "==> #{message}"
  @doc "Print an informational message in green"
  def info(message),  do: IO.puts "==> #{IO.ANSI.green}#{message}#{IO.ANSI.reset}"
  @doc "Print a warning message in yellow"
  def warn(message),  do: IO.puts "==> #{IO.ANSI.yellow}#{message}#{IO.ANSI.reset}"
  @doc "Print a notice in yellow"
  def notice(message), do: IO.puts "#{IO.ANSI.yellow}#{message}#{IO.ANSI.reset}"
  @doc "Print an error message in red"
  def error(message), do: IO.puts "==> #{IO.ANSI.red}#{message}#{IO.ANSI.reset}"
end

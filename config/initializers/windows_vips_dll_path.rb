# On Windows, Ruby's FFI (which ruby-vips uses to bind to libvips) does
# not consult PATH when resolving the DLL name you ask it to load —
# LoadLibrary only searches PATH for *that* DLL's own dependencies, not
# for the top-level DLL itself, unless its directory is registered via
# SetDllDirectory first. Without this, the first image thumbnail
# generated on Windows (see FilesController / app/views/files/index)
# raises a LoadError even with libvips correctly installed and on PATH.
#
# Not needed in Docker/production — the Dockerfile installs libvips via
# apt, and Linux's dynamic linker searches the system library path
# normally without this workaround.
if Gem.win_platform?
  require "fiddle/import"

  module WindowsDllDirectory # :nodoc:
    extend Fiddle::Importer
    dlload "kernel32.dll"
    extern "int SetDllDirectoryA(const char*)"
  end

  vips_bin_candidates = [
    ENV["VIPS_BIN_PATH"],
    File.expand_path("~/scoop/apps/libvips/current/bin"),
    *Dir["C:/ProgramData/chocolatey/lib/libvips/tools/vips-dev-*/bin"],
    *Dir["C:/vips*/bin"]
  ].compact

  vips_bin = vips_bin_candidates.find { |path| File.directory?(path) }
  WindowsDllDirectory.SetDllDirectoryA(vips_bin) if vips_bin
end

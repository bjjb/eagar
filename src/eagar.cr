require "ini"
require "yaml"
require "json"

module Eagar
  VERSION = "0.1.0"

  alias YAMLConfig = Hash(String, String | Hash(String, String))
  alias INIConfig = Hash(String, Hash(String, String))

  class_property system = Path["/etc"]
  class_property site = Path["/usr/local/etc"]
  class_property user = Path["~"].expand(home: true)
  class_property xdg = Path[ENV.fetch("XDG_CONFIG_HOME", "~/.config")].expand(home: true)

  def self.system_config_dirs : Array(Path)
    if xdg_dirs = ENV["XDG_CONFIG_DIRS"]?
      xdg_dirs.split(':').map { |dir| Path[dir] }
    else
      [system, site]
    end
  end

  def self.configuration(name, secondary = "config", extensions = %w(json yaml ini))
    files(name).reduce({"" => ({} of String => String)}) do |cfg, path|
      cfg.tap do |cfg|
        parse(path).each do |k, v|
          cfg[k] = cfg.fetch(k) { {} of String => String }.merge(v)
        end
      end
    end
  end

  def self.parse(path) : Hash(String, Hash(String, String))
    if %w(.ini .conf).includes?(File.extname(path))
      return INI.parse(File.read(path))
    end
    {"" => Hash(String, String).from_yaml(File.read(path))}
  end

  def self.files(name, secondary = "config", extensions = %w(json yaml ini))
    Dir.glob(globs(name, secondary, extensions)).map do |filename|
      Path[filename]
    end.select do |path|
      File.exists?(path) && File::Info.readable?(path)
    end
  end

  def self.globs(name, secondary = "config", extensions = %w(json yaml ini))
    extglob = "{#{extensions.join(',')}}"
    cwd = Path["."].expand(home: true)

    result = [] of Path

    # System config directories (respects XDG_CONFIG_DIRS)
    system_config_dirs.each do |dir|
      result << dir / "#{name}.#{extglob}"
      result << dir / "#{name}/#{secondary}.#{extglob}"
      result << dir / "#{name}/#{secondary}.d/*.#{extglob}"
    end

    # User home directory
    result << user / ".#{name}.#{extglob}"
    result << user / ".#{name}/#{secondary}.#{extglob}"
    result << user / ".#{name}/#{secondary}.d/*.#{extglob}"

    # XDG config directory (respects XDG_CONFIG_HOME)
    result << xdg / "#{name}.#{extglob}"
    result << xdg / "#{name}/#{secondary}.#{extglob}"
    result << xdg / "#{name}/#{secondary}.d/*.#{extglob}"

    # Current working directory
    result << cwd / ".#{name}.#{extglob}"
    result << cwd / ".#{name}/#{secondary}.#{extglob}"
    result << cwd / ".#{name}/#{secondary}.d/*.#{extglob}"
    result << cwd / ".config/#{name}.#{extglob}"
    result << cwd / ".config/#{name}/#{secondary}.#{extglob}"
    result << cwd / ".config/#{name}/#{secondary}.d/*.#{extglob}"

    result
  end
end

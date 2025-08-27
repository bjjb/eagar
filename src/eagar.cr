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
  class_property xdg = Path["~/.config"].expand(home: true)

  def self.configuration(name, secondary = "config", extensions = %w(json yaml ini))
    files(name).reduce({ "" => ({} of String => String) }) do |cfg, path|
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
    { "" => Hash(String, String).from_yaml(File.read(path)) }
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
    [
      system / "#{name}.#{extglob}",
      system / "#{name}/#{secondary}.#{extglob}",
      system / "#{name}/#{secondary}.d/*.#{extglob}",
      site / "#{name}.#{extglob}",
      site / "#{name}/#{secondary}.#{extglob}",
      site / "#{name}/#{secondary}.d/*.#{extglob}",
      user / ".#{name}.#{extglob}",
      user / ".#{name}/#{secondary}.#{extglob}",
      user / ".#{name}/#{secondary}.d/*.#{extglob}",
      xdg / "#{name}.#{extglob}",
      xdg / "#{name}/#{secondary}.#{extglob}",
      xdg / "#{name}/#{secondary}.d/*.#{extglob}",
      cwd / ".#{name}.#{extglob}",
      cwd / ".#{name}/#{secondary}.#{extglob}",
      cwd / ".#{name}/#{secondary}.d/*.#{extglob}",
      cwd / ".config/#{name}.#{extglob}",
      cwd / ".config/#{name}/#{secondary}.#{extglob}",
      cwd / ".config/#{name}/#{secondary}.d/*.#{extglob}",
    ]
  end
end

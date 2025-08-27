require "ini"
require "yaml"
require "json"

module Eagar
  VERSION = "0.1.0"

  class_property system = Path["/etc"]
  class_property site = Path["/usr/local/etc"]
  class_property user = Path["~"].expand(home: true)
  class_property xdg = Path["~/.config"].expand(home: true)

  alias Parser = IO -> Hash(String, Hash(String, String))

  class_property parsers : Hash(String, Parser) = {
    "json" => ->(io : IO) { Hash(String, Hash(String, String)).from_json(io) },
    "yaml" => ->(io : IO) { Hash(String, Hash(String, String)).from_yaml(io) },
    "ini" => ->(io : IO) { INI.parse(io) },
  }

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

  def self.files(name, secondary = "config", extensions = %w(json yaml ini))
    Dir.glob(globs(name, secondary, extensions)).map do |filename|
      Path[filename]
    end.select do |path|
      File.exists?(path) && File::Info.readable?(path)
    end
  end
end

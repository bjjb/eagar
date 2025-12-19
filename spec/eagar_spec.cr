require "spec"
require "file_utils"
require "../src/eagar"

describe Eagar do
  it "will look in typical locations for all files" do
    xdg = Eagar.xdg
    Eagar.globs("x", "y", %w(json yaml)).should eq [
      Path["/etc/x.{json,yaml}"],
      Path["/etc/x/y.{json,yaml}"],
      Path["/etc/x/y.d/*.{json,yaml}"],
      Path["/usr/local/etc/x.{json,yaml}"],
      Path["/usr/local/etc/x/y.{json,yaml}"],
      Path["/usr/local/etc/x/y.d/*.{json,yaml}"],
      Path["~/.x.{json,yaml}"].expand(home: true),
      Path["~/.x/y.{json,yaml}"].expand(home: true),
      Path["~/.x/y.d/*.{json,yaml}"].expand(home: true),
      xdg / "x.{json,yaml}",
      xdg / "x/y.{json,yaml}",
      xdg / "x/y.d/*.{json,yaml}",
      Path[".x.{json,yaml}"].expand(home: true),
      Path[".x/y.{json,yaml}"].expand(home: true),
      Path[".x/y.d/*.{json,yaml}"].expand(home: true),
      Path[".config/x.{json,yaml}"].expand(home: true),
      Path[".config/x/y.{json,yaml}"].expand(home: true),
      Path[".config/x/y.d/*.{json,yaml}"].expand(home: true),
    ]
  end

  it "defaults to using \"config\" for config file base names" do
    xdg = Eagar.xdg
    Eagar.globs("x").should eq [
      Path["/etc/x.{json,yaml,ini}"],
      Path["/etc/x/config.{json,yaml,ini}"],
      Path["/etc/x/config.d/*.{json,yaml,ini}"],
      Path["/usr/local/etc/x.{json,yaml,ini}"],
      Path["/usr/local/etc/x/config.{json,yaml,ini}"],
      Path["/usr/local/etc/x/config.d/*.{json,yaml,ini}"],
      Path["~/.x.{json,yaml,ini}"].expand(home: true),
      Path["~/.x/config.{json,yaml,ini}"].expand(home: true),
      Path["~/.x/config.d/*.{json,yaml,ini}"].expand(home: true),
      xdg / "x.{json,yaml,ini}",
      xdg / "x/config.{json,yaml,ini}",
      xdg / "x/config.d/*.{json,yaml,ini}",
      Path[".x.{json,yaml,ini}"].expand(home: true),
      Path[".x/config.{json,yaml,ini}"].expand(home: true),
      Path[".x/config.d/*.{json,yaml,ini}"].expand(home: true),
      Path[".config/x.{json,yaml,ini}"].expand(home: true),
      Path[".config/x/config.{json,yaml,ini}"].expand(home: true),
      Path[".config/x/config.d/*.{json,yaml,ini}"].expand(home: true),
    ]
  end

  it "loads configuration from all the files it can find" do
    FileUtils.mkdir_p(tmpdir = Path[File.tempname("x")])
    Dir.cd(tmpdir) do
      FileUtils.mkdir_p(".x/config.d")
      Eagar.files("x").should eq %w()
      File.open(".x/config.d/foo.ini", "w", &.puts("x = y"))
      Eagar.files("x").should eq [tmpdir / ".x/config.d/foo.ini"]
      File.open(".x/config.d/bar.json", "w", &.puts(%({"y":"z"})))
      Eagar.files("x").should eq [
        tmpdir / ".x/config.d/bar.json",
        tmpdir / ".x/config.d/foo.ini",
      ]
      File.open(".x.yaml", "w", &.puts("a: b"))
      Eagar.files("x").should eq [
        tmpdir / ".x.yaml",
        tmpdir / ".x/config.d/bar.json",
        tmpdir / ".x/config.d/foo.ini",
      ]
      FileUtils.mkdir_p(".config/x/config.d")
      File.open(".config/x/config.d/foo.yaml", "w", &.puts("b: c"))
      Eagar.files("x").should eq [
        tmpdir / ".x.yaml",
        tmpdir / ".x/config.d/bar.json",
        tmpdir / ".x/config.d/foo.ini",
        tmpdir / ".config/x/config.d/foo.yaml",
      ]
      File.open(".x.ini", "w", &.puts("[foo]\nbar=baz"))
      Eagar.configuration("x").keys.should contain("")
      Eagar.configuration("x").keys.should contain("foo")
      Eagar.configuration("x")["foo"]["bar"].should eq "baz"
    end
  ensure
    tmpdir.try { |d| FileUtils.rm_rf(d) }
  end

  it "initializes xdg property from XDG_CONFIG_HOME if set, otherwise uses default" do
    # Verify that Eagar.xdg respects XDG Base Directory specification
    # It should use ENV["XDG_CONFIG_HOME"] if set, otherwise default to ~/.config

    if xdg_home = ENV["XDG_CONFIG_HOME"]?
      # If XDG_CONFIG_HOME is set in environment, Eagar.xdg should use it
      Eagar.xdg.should eq(Path[xdg_home].expand(home: true))
    else
      # If not set, should default to ~/.config
      Eagar.xdg.should eq(Path["~/.config"].expand(home: true))
    end
  end
end

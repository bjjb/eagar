require "spec"
require "file_utils"
require "../src/eagar"

describe Eagar do
  it "will look in typical locations for all files" do
    xdg = Eagar.xdg
    sys_dirs = Eagar.system_config_dirs

    expected = [] of Path

    # System config directories
    sys_dirs.each do |dir|
      expected << dir / "x.{json,yaml}"
      expected << dir / "x/y.{json,yaml}"
      expected << dir / "x/y.d/*.{json,yaml}"
    end

    # User home directory
    expected << Path["~/.x.{json,yaml}"].expand(home: true)
    expected << Path["~/.x/y.{json,yaml}"].expand(home: true)
    expected << Path["~/.x/y.d/*.{json,yaml}"].expand(home: true)

    # XDG config directory
    expected << xdg / "x.{json,yaml}"
    expected << xdg / "x/y.{json,yaml}"
    expected << xdg / "x/y.d/*.{json,yaml}"

    # Current directory
    expected << Path[".x.{json,yaml}"].expand(home: true)
    expected << Path[".x/y.{json,yaml}"].expand(home: true)
    expected << Path[".x/y.d/*.{json,yaml}"].expand(home: true)
    expected << Path[".config/x.{json,yaml}"].expand(home: true)
    expected << Path[".config/x/y.{json,yaml}"].expand(home: true)
    expected << Path[".config/x/y.d/*.{json,yaml}"].expand(home: true)

    Eagar.globs("x", "y", %w(json yaml)).should eq expected
  end

  it "defaults to using \"config\" for config file base names" do
    xdg = Eagar.xdg
    sys_dirs = Eagar.system_config_dirs

    expected = [] of Path

    # System config directories
    sys_dirs.each do |dir|
      expected << dir / "x.{json,yaml,ini}"
      expected << dir / "x/config.{json,yaml,ini}"
      expected << dir / "x/config.d/*.{json,yaml,ini}"
    end

    # User home directory
    expected << Path["~/.x.{json,yaml,ini}"].expand(home: true)
    expected << Path["~/.x/config.{json,yaml,ini}"].expand(home: true)
    expected << Path["~/.x/config.d/*.{json,yaml,ini}"].expand(home: true)

    # XDG config directory
    expected << xdg / "x.{json,yaml,ini}"
    expected << xdg / "x/config.{json,yaml,ini}"
    expected << xdg / "x/config.d/*.{json,yaml,ini}"

    # Current directory
    expected << Path[".x.{json,yaml,ini}"].expand(home: true)
    expected << Path[".x/config.{json,yaml,ini}"].expand(home: true)
    expected << Path[".x/config.d/*.{json,yaml,ini}"].expand(home: true)
    expected << Path[".config/x.{json,yaml,ini}"].expand(home: true)
    expected << Path[".config/x/config.{json,yaml,ini}"].expand(home: true)
    expected << Path[".config/x/config.d/*.{json,yaml,ini}"].expand(home: true)

    Eagar.globs("x").should eq expected
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

  it "uses XDG_CONFIG_DIRS if set, otherwise traditional paths" do
    # Verify that system config directories respect XDG_CONFIG_DIRS
    # Should use colon-separated XDG_CONFIG_DIRS if set, otherwise /etc and /usr/local/etc

    globs = Eagar.globs("testapp")

    if xdg_dirs = ENV["XDG_CONFIG_DIRS"]?
      # If XDG_CONFIG_DIRS is set, globs should include those directories
      xdg_dirs.split(':').each do |dir|
        globs.should contain(Path[dir] / "testapp.{json,yaml,ini}")
      end
      # And should NOT contain the default paths
      globs.should_not contain(Path["/etc/testapp.{json,yaml,ini}"])
      globs.should_not contain(Path["/usr/local/etc/testapp.{json,yaml,ini}"])
    else
      # If not set, should use traditional Unix paths
      globs.should contain(Path["/etc/testapp.{json,yaml,ini}"])
      globs.should contain(Path["/usr/local/etc/testapp.{json,yaml,ini}"])
    end
  end
end

require "spec"
require "file_utils"
require "../src/eagar"

describe Eagar do
  it "will look in typical locations for all files" do
    Eagar.globs("x", "y", %w(json yaml)).should eq %w(
      /etc/x.{json,yaml}
      /etc/x/y.{json,yaml}
      /etc/x/y.d/*.{json,yaml}
      /usr/local/etc/x.{json,yaml}
      /usr/local/etc/x/y.{json,yaml}
      /usr/local/etc/x/y.d/*.{json,yaml}
      ~/.x.{json,yaml}
      ~/.x/y.{json,yaml}
      ~/.x/y.d/*.{json,yaml}
      ~/.config/x.{json,yaml}
      ~/.config/x/y.{json,yaml}
      ~/.config/x/y.d/*.{json,yaml}
      .x.{json,yaml}
      .x/y.{json,yaml}
      .x/y.d/*.{json,yaml}
      .config/x.{json,yaml}
      .config/x/y.{json,yaml}
      .config/x/y.d/*.{json,yaml}
    ).map { |filename| Path[filename].expand(home: true) }
  end

  it "defaults to using \"config\" for config file base names" do
    Eagar.globs("x").should eq %w(
      /etc/x.{json,yaml,ini}
      /etc/x/config.{json,yaml,ini}
      /etc/x/config.d/*.{json,yaml,ini}
      /usr/local/etc/x.{json,yaml,ini}
      /usr/local/etc/x/config.{json,yaml,ini}
      /usr/local/etc/x/config.d/*.{json,yaml,ini}
      ~/.x.{json,yaml,ini}
      ~/.x/config.{json,yaml,ini}
      ~/.x/config.d/*.{json,yaml,ini}
      ~/.config/x.{json,yaml,ini}
      ~/.config/x/config.{json,yaml,ini}
      ~/.config/x/config.d/*.{json,yaml,ini}
      .x.{json,yaml,ini}
      .x/config.{json,yaml,ini}
      .x/config.d/*.{json,yaml,ini}
      .config/x.{json,yaml,ini}
      .config/x/config.{json,yaml,ini}
      .config/x/config.d/*.{json,yaml,ini}
    ).map { |filename| Path[filename].expand(home: true) }
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
    end
  ensure
    tmpdir.try { |d| FileUtils.rm_rf(d) }
  end
end

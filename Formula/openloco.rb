class Openloco < Formula
  desc "Open-source re-implementation of Chris Sawyer's Locomotion"
  homepage "https://openloco.io/"
  url "https://api.github.com/repos/OpenLoco/OpenLoco/tarball/v25.12"
  sha256 "a05b6c33d87c8171fe981d2fa0dba66dda490db6d977c0ead0b0c1e4825119e8"
  license "MIT"
  head "https://github.com/OpenLoco/OpenLoco.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "openal-soft"
  depends_on "libpng"
  depends_on "sdl2"
  depends_on "yaml-cpp"
  depends_on "fmt"
  depends_on macos: :sonoma

  resource "sfl" do
    url "https://api.github.com/repos/OpenLoco/OpenLoco/tarball/v25.12"
    sha256 "a05b6c33d87c8171fe981d2fa0dba66dda490db6d977c0ead0b0c1e4825119e8"
  end

  resource "openloco_objects" do
    url "https://api.github.com/repos/OpenLoco/OpenLoco/tarball/v25.12"
    sha256 "a05b6c33d87c8171fe981d2fa0dba66dda490db6d977c0ead0b0c1e4825119e8"
  end

  # Dependencies handled by CMake FetchContent (no need to specify):
  # - yaml-cpp (fetched if not found)
  # - fmt (fetched if not found)
  # - sfl-library (always fetched)
  # - OpenGraphics objects (fetched during build)

  def install
    # openal-soft is keg-only, so we need to tell CMake where to find it
    (buildpath/"sfl").install resource("sfl")
    (buildpath/"openloco_objects").install resource("openloco_objects")

    args = %W[
      -DCMAKE_PREFIX_PATH=#{Formula["openal-soft"].opt_prefix};#{HOMEBREW_PREFIX}
      -DFETCHCONTENT_SOURCE_DIR_SFL=#{buildpath}/sfl
      -DFETCHCONTENT_SOURCE_DIR_OPENLOCO_OBJECTS=#{buildpath}/openloco_objects
      -DOPENLOCO_BUILD_TESTS=OFF
      -DOPENLOCO_HEADER_CHECK=OFF
      -DSTRICT=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build", "--config", "Release"

    # On macOS, the build creates an .app bundle
    prefix.install "build/OpenLoco.app"
    bin.write_exec_script prefix/"OpenLoco.app/Contents/MacOS/OpenLoco"
  end

  def caveats
    <<~EOS
      OpenLoco requires the asset files from the original Chris Sawyer's Locomotion.
      You can purchase the game from:
        - Steam: https://store.steampowered.com/app/356430/
        - GOG: https://www.gog.com/game/chris_sawyers_locomotion

      The game will prompt for the location of the original game files on first launch.

      To add OpenLoco to your Applications folder, run:
        ln -s #{prefix}/OpenLoco.app /Applications/OpenLoco.app
    EOS
  end

  test do
    # Basic test - check the .app bundle was created
    assert_predicate prefix/"OpenLoco.app/Contents/MacOS/OpenLoco", :exist?

    # Verify it's a valid Mach-O binary
    system "file", "#{prefix}/OpenLoco.app/Contents/MacOS/OpenLoco"
  end
end

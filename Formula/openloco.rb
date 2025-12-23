class Openloco < Formula
  desc "Open-source re-implementation of Chris Sawyer's Locomotion"
  homepage "https://openloco.io/"
  url "https://github.com/OpenLoco/OpenLoco/archive/refs/tags/v25.12.tar.gz"
  sha256 "11e06a365c083940665cfeaa0c367686b9171733cd05bb7692222226b74a716e"
  license "MIT"
  head "https://github.com/OpenLoco/OpenLoco.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "fmt"
  depends_on "libpng"
  depends_on "openal-soft"
  depends_on "sdl2"
  depends_on "yaml-cpp"

  on_macos do
    depends_on macos: :sonoma
  end

  resource "sfl" do
    url "https://github.com/slavenf/sfl-library/archive/refs/tags/2.0.2.tar.gz"
    sha256 "b3548e5efb618afa82a5bae7026168b3394d4b06c23dd1ba94d02b69b4bb7244"
  end

  resource "openloco_objects" do
    url "https://github.com/OpenLoco/OpenGraphics/releases/download/v0.1.6/objects.zip"
    sha256 "4cea1ab77131650b5475b489445ce65c275b3a23b921456afda4d9c5c83e580c"
  end

  def install
    odie "OpenLoco is currently only supported on ARM-based Macs." if OS.mac? && Hardware::CPU.intel?
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

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build", "--config", "Release"

    if OS.mac?
      prefix.install "build/OpenLoco.app"
      bin.write_exec_script prefix/"OpenLoco.app/Contents/MacOS/OpenLoco"
      (prefix/"OpenLoco.app/Contents/Resources").install buildpath/"openloco_objects" => "objects"
    else
      system "cmake", "--install", "build"
    end
  end

  def caveats
    msg = <<~EOS
      OpenLoco requires the asset files from the original Chris Sawyer's Locomotion.
      You can purchase the game from:
        - Steam: https://store.steampowered.com/app/356430/
        - GOG: https://www.gog.com/game/chris_sawyers_locomotion

      The game will prompt for the location of the original game files on first launch.
    EOS

    if OS.mac?
      msg += <<~EOS

        To add OpenLoco to your Applications folder, run:
          ln -s #{prefix}/OpenLoco.app /Applications/OpenLoco.app
      EOS
    end

    msg
  end

  test do
    if OS.mac?
      assert_path_exists prefix/"OpenLoco.app/Contents/MacOS/OpenLoco", :exist?
      system "file", "#{prefix}/OpenLoco.app/Contents/MacOS/OpenLoco"
    else
      assert_path_exists bin/"OpenLoco", :exist?
      system "file", "#{bin}/OpenLoco"
    end
  end
end

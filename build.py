import subprocess


def install_dependencies():
    subprocess.run(
        "sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev",
        shell=True,
    )
    subprocess.run("sudo apt-get install -y libmpv-dev", shell=True)


def build_flutter():
    subprocess.run("flutter pub get", shell=True)
    subprocess.run(
        "dart run build_runner build --delete-conflicting-outputs", shell=True
    )
    subprocess.run("flutter build linux --release", shell=True)


def compress_build():
    subprocess.run(
        "tar -czvf flubar.tar.gz -C build/linux/x64/release/bundle .", shell=True
    )


if __name__ == "__main__":
    install_dependencies()
    build_flutter()
    compress_build()

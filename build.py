import subprocess


def install_dependencies():
    subprocess.run(
        "sudo apt-get update -y && sudo apt-get upgrade -y", shell=True)
    subprocess.run(
        "sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa", shell=True)
    subprocess.run(
        "sudo apt-get install -y clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev",
        shell=True,
    )
    subprocess.run(
        "sudo apt-get install -y pkg-config libmpv-dev libcue-dev", shell=True)


def build():
    subprocess.run("flutter pub get", shell=True)
    subprocess.run(
        "dart run build_runner build --delete-conflicting-outputs", shell=True
    )
    subprocess.run("flutter build linux --release -v", shell=True)


def package():
    subprocess.run(
        "tar -czvf flubar.tar.gz -C build/linux/x64/release/bundle .", shell=True
    )


if __name__ == "__main__":
    build()
    package()

import os
import subprocess


def build():
    env = os.environ.copy()

    subprocess.run("flutter pub get", shell=True, env=env)
    subprocess.run("touch rust/src/frb_generated.rs", shell=True, env=env)
    subprocess.run("flutter_rust_bridge_codegen generate", shell=True, env=env)
    subprocess.run("flutter build macos --release -v", shell=True, env=env, check=True)


def package():
    env = os.environ.copy()
    subprocess.run(
        "tar -czvf flubar.tar.gz -C build/macos/Build/Products/Release flubar.app",
        shell=True,
        env=env,
        check=True,
    )


if __name__ == "__main__":
    build()
    package()

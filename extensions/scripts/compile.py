import argparse
import os
import platform
import subprocess
import stat

from typing import List

docker_image_map = {
    "x86_64": "x64",
    "x86": "x86",
    "aarch64": "arm64",
    "riscv64": "riscv64"
}


def setup_docker_image(target_arch: str, project_dir: str) -> str:
    extensions_dir = os.path.join(project_dir, "extensions")
    docker_image_name = "dockcross/linux-{}".format(docker_image_map[target_arch])

    os.makedirs(os.path.join(extensions_dir, "cross_compile_stuff"), exist_ok=True)
    compiler_script = os.path.join(extensions_dir, "cross_compile_stuff", "{}.sh".format(target_arch))

    # run the docker image and capture the output
    docker_result = subprocess.run(
        ["docker", "run", docker_image_name],
        cwd=project_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    with open(compiler_script, "w") as f:
        f.write(docker_result.stdout.decode("utf-8"))

    os.chmod(compiler_script, os.stat(compiler_script).st_mode | stat.S_IXUSR)

    return compiler_script


if __name__ == "__main__":
    script_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    extensions_dir = os.path.join(script_dir, "..")
    project_dir = os.path.join(extensions_dir, "..")
    default_api_file = os.path.join(extensions_dir, "extension_api.json")

    host_os = platform.system()
    host_arch = platform.machine()

    parser = argparse.ArgumentParser(
        description="compile the gdextension"
    )

    parser.add_argument(
        "--mode",
        type=str,
        default="debug",
        choices=["release", "debug"],
        help="The compilation mode (default: debug)",
        dest="build_mode"
    )

    parser.add_argument(
        "--api_file",
        type=str,
        default=default_api_file,
        help="The API file to use (default: {})".format(default_api_file)
    )
    
    parser.add_argument(
        "--target_arch",
        type=str,
        default=host_arch,
        help="The target architecture (default: {})".format(host_arch)
    )

    parser.add_argument(
        "--build_dir",
        type=str,
        required=False,
        help="The build directory (default: build_<target_arch>_<build_mode>)"
    )

    parser.add_argument(
        "--build_system",
        type=str,
        required=False,
        default="-GNinja",
        help="The build system cmake should use under the hood (default: -GNinja)"
    )

    args = vars(parser.parse_args())
    print(args)

    cmake_command: List[str] = []

    if args["target_arch"] == "native":
        args["target_arch"] = host_arch

    if host_arch == args["target_arch"]:
        print("Building natively for the host architecture ({})".format(host_arch))

        cmake_command = ["cmake"]
    else:
        print("Building with docker for the target architecture: {}".format(args["target_arch"]))
        
        compiler_script = setup_docker_image(args["target_arch"], project_dir)
        compiler_script = os.path.abspath(compiler_script)

        cmake_command = [compiler_script, "cmake"]

    # Set the build directory
    build_dir = os.path.join("extensions", "build_{}_{}".format(args["target_arch"], args["build_mode"]))
    if args["build_dir"]:
        build_dir = args["build_dir"]

    os.makedirs(build_dir, exist_ok=True)

    # Run the setup command
    setup_command = [
        *cmake_command,
        "-DCMAKE_BUILD_TYPE={}".format(args["build_mode"].capitalize()),
        "-DGODOT_GDEXTENSION_API_FILE={}".format(args["api_file"]),
        "-B", build_dir,
        args["build_system"],
        "extensions"
    ]
    if subprocess.call(setup_command, cwd=project_dir) != 0:
        print("Failed to run the setup command")
        exit(1)

    # Compile the source file
    compile_command = [*cmake_command, "--build", build_dir]
    if subprocess.call(compile_command, cwd=project_dir) != 0:
        print("Failed to run the compile command")
        exit(1)

    # install the build output
    install_command = [*cmake_command, "--install", build_dir]
    if subprocess.call(install_command, cwd=project_dir) != 0:
        print("Failed to install the build output")
        exit(1)
    

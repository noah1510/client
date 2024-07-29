import argparse
import os
import zipfile
import sys
from pathlib import Path

import wget


def main(args):
    godot_repo = args["godot_repo"]
    godot_version = args["godot_version"]

    system_type = ""
    export_template_dir = ""
    godot_program_subdir = ""
    godot_console_subdir = ""
    match sys.platform:
        case ["linux"]:
            system_type = "linux.x86_64"
            export_template_dir = f"~/.local/share/godot/export_templates/{godot_version}"
            godot_program_subdir = f"Godot_v{godot_version}_linux.x86_64"
            godot_console_subdir = godot_program_subdir
        case ["win32"] | ["cygwin"]:
            system_type = "win64.exe"
            export_template_dir = f"{os.getenv('APPDATA')}/Godot/templates/{godot_version}"
            godot_program_subdir = f"Godot_v{godot_version}_win64.exe"
            godot_console_subdir = f"Godot_v{godot_version}_win64_console.exe"
        case ["darwin"]:
            system_type = "macos.universal"
            export_template_dir = f"~/Library/Application Support/Godot/templates/{godot_version}"
            godot_program_subdir = f"Godot.app/Contents/MacOS/Godot"
            godot_console_subdir = godot_program_subdir
        case _: os.exit(1)

    export_template_dir = str(Path.expanduser(export_template_dir))

    # create the .godot_installs dir and the templates dir
    godot_installs_dir = os.path.join(script_dir, ".godot_installs", godot_version)
    os.makedirs(godot_installs_dir, exist_ok=True)
    os.makedirs(export_template_dir, exist_ok=True)

    # download the godot executable
    godot_exe_zip = f"Godot_v{godot_version}_{system_type}.zip"
    godot_download_link = f"{godot_repo}/releases/download/{godot_version}/{godot_exe_zip}"
    godot_zip = wget.download(godot_download_link)

    # unzip the godot executable
    with zipfile.ZipFile(godot_zip, "r") as zip_ref:
        zip_ref.extractall(godot_installs_dir)

    # remove the zip file
    os.remove(godot_zip)

    # download the export templates
    godot_templates_zip_name = f"Godot_v{godot_version}_export_templates.tpz"
    godot_templates_link = f"{godot_repo}/releases/download/{godot_version}/{godot_templates_zip_name}"
    godot_templates_zip = wget.download(godot_templates_link)

    # unzip the export templates
    with zipfile.ZipFile(godot_templates_zip, "r") as zip_ref:
        zip_ref.extractall(export_template_dir)

    # set and export the environment variables for the godot executable
    env_file = os.getenv('GITHUB_OUTPUT')
    with open(env_file, "a") as file:
        file.write(f"GODOT_EXE={os.path.join(godot_installs_dir, godot_program_subdir)}\n")
        file.write(f"GODOT_CONSOLE_EXE={os.path.join(godot_installs_dir, godot_console_subdir)}\n")


if __name__ == "__main__":
    # change to the project root, which is the dir of this file
    script_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    os.chdir(script_dir)

    parser = argparse.ArgumentParser(
        description="setup the godot executable"
    )

    parser.add_argument(
        "--godot_repo",
        action="store",
        help="The repository to download the godot executable from",
        default="https://github.com/godotengine/godot-builds",
        dest="godot_repo",
        required=False,
    )

    parser.add_argument(
        "--godot_version",
        action="store",
        help="The version tag to download",
        default="4.3-rc1",
        dest="godot_repo",
        required=False,
    )

    args = vars(parser.parse_args())

    main(args)

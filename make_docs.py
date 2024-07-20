import argparse
import os
import subprocess


def main(args):
    gd_exe = args["godot_path"]
    
    # Check if the godot executable exists
    if not os.path.exists(gd_exe):
        print(f"Godot executable not found at {gd_exe}")
        return
    
    # make sure the godot executable is executable
    _ret = subprocess.run([gd_exe, "--version"], check=True)
    if _ret.returncode != 0:
        print(f"Failed to run godot executable at {gd_exe}")
        return
    
    os.makedirs(args["doc_dir"], exist_ok=True)

    # mat
    gd_scrip_dirs = [
        #"addons",
        "classes",
        "scenes",
        "scripts",
        "ui",
    ]

    
    print(gd_scrip_dirs)

    # generate the documentation
    for gd_file in gd_scrip_dirs:
        gd_dir = "res://" + gd_file

        print(f"Generating documentation for {gd_dir}")
        try:
            _ret = subprocess.run([
                gd_exe,
                "--headless",
                "--verbose",
                "--doctool",
                args["doc_dir"],
                "--gdscript-docs",
                gd_dir
            ], check=False, timeout=10)
        except subprocess.TimeoutExpired:
            print(f"Failed to generate documentation for {gd_dir} due to timeout")
            continue


if __name__ == "__main__":
    # change to the project root, which is the dir of this file
    script_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    os.chdir(script_dir)

    parser = argparse.ArgumentParser(
        description="build the documentation for the openchamp project"
    )

    parser.add_argument(
        "--output",
        action="store",
        help="The output directory for the documentation",
        default="docs",
        dest="doc_dir",
        required=False,
    )

    parser.add_argument(
        "godot_path",
        action="store",
        help="The path to the godot executable",
    )

    args = vars(parser.parse_args())

    main(args)

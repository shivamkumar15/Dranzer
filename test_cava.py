import shutil, os, subprocess
cava_bin = shutil.which("cava")
if cava_bin:
    shutil.copy2(cava_bin, "/tmp/cava_test_bin")
    os.chmod("/tmp/cava_test_bin", 0o755)
    print("Copied")

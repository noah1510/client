#!/bin/bash

# Use xvfb-run to run the command unless RUNNER_OS is Windows
if [ "$RUNNER_OS" == "Windows" ]; then
    $@
else
    export LIBGL_ALWAYS_SOFTWARE="true"
    export GALLIUM_DRIVER="llvmpipe"
    export MESA_VK_DEVICE_SELECT="llvmpipe"
    export DISPLAY=":42"
    
    xvfb-run $@
fi

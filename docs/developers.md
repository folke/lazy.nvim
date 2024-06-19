---
sidebar_position: 7
---
# 📚 Plugin Developers

If your plugin needs a build step, you can create a file `build.lua` or `build/init.lua`
in the root of your repo. This file will be loaded when the plugin is installed or updated.

This makes it easier for users, as they no longer need to specify a `build` command.


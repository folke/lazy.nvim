---
sidebar_position: 7
---
# 📚 Plugin Developers

To make it easier for users to install your plugin, you can include a [package spec](/packages) in your repo.

If your plugin needs a build step, you can specify this in your **package file**,
or create a file `build.lua` or `build/init.lua` in the root of your repo.
This file will be loaded when the plugin is installed or updated.

This makes it easier for users, as they no longer need to specify a `build` command.


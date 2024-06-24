<h4 align="center">
  <a href="https://lazy.folke.io/installation">Install</a>
  ·
  <a href="https://lazy.folke.io/configuration">Configure</a>
  ·
  <a href="https://lazy.folke.io">Docs</a>
</h4>

<div align="center"><p>
    <a href="https://github.com/folke/lazy.nvim/releases/latest">
      <img alt="Latest release" src="https://img.shields.io/github/v/release/folke/lazy.nvim?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=D9E0EE&labelColor=302D41&include_prerelease&sort=semver" />
    </a>
    <a href="https://github.com/folke/lazy.nvim/pulse">
      <img alt="Last commit" src="https://img.shields.io/github/last-commit/folke/lazy.nvim?style=for-the-badge&logo=starship&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41"/>
    </a>
    <a href="https://github.com/folke/lazy.nvim/blob/main/LICENSE">
      <img alt="License" src="https://img.shields.io/github/license/folke/lazy.nvim?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/folke/lazy.nvim/stargazers">
      <img alt="Stars" src="https://img.shields.io/github/stars/folke/lazy.nvim?style=for-the-badge&logo=starship&color=c69ff5&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/folke/lazy.nvim/issues">
      <img alt="Issues" src="https://img.shields.io/github/issues/folke/lazy.nvim?style=for-the-badge&logo=bilibili&color=F5E0DC&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/folke/lazy.nvim">
      <img alt="Repo Size" src="https://img.shields.io/github/repo-size/folke/lazy.nvim?color=%23DDB6F2&label=SIZE&logo=codesandbox&style=for-the-badge&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://twitter.com/intent/follow?screen_name=folke">
      <img alt="follow on Twitter" src="https://img.shields.io/twitter/follow/folke?style=for-the-badge&logo=twitter&color=8aadf3&logoColor=D9E0EE&labelColor=302D41" />
    </a>
</div>



**lazy.nvim** is a modern plugin manager for Neovim.

![image](https://user-images.githubusercontent.com/292349/208301737-68fb279c-ba70-43ef-a369-8c3e8367d6b1.png)

## ✨ Features

- 📦 Manage all your Neovim plugins with a powerful UI
- 🚀 Fast startup times thanks to automatic caching and bytecode compilation of Lua modules
- 💾 Partial clones instead of shallow clones
- 🔌 Automatic lazy-loading of Lua modules and lazy-loading on events, commands, filetypes, and key mappings
- ⏳ Automatically install missing plugins before starting up Neovim, allowing you to start using it right away
- 💪 Async execution for improved performance
- 🛠️ No need to manually compile plugins
- 🧪 Correct sequencing of dependencies
- 📁 Configurable in multiple files
- 📚 Generates helptags of the headings in `README.md` files for plugins that don't have vimdocs
- 💻 Dev options and patterns for using local plugins
- 📊 Profiling tools to optimize performance
- 🔒 Lockfile `lazy-lock.json` to keep track of installed plugins
- 🔎 Automatically check for updates
- 📋 Commit, branch, tag, version, and full [Semver](https://devhints.io/semver) support
- 📈 Statusline component to see the number of pending updates
- 🎨 Automatically lazy-loads colorschemes

## ⚡️ Requirements

- Neovim >= **0.8.0** (needs to be built with **LuaJIT**)
- Git >= **2.19.0** (for partial clones support)
- a [Nerd Font](https://www.nerdfonts.com/) **_(optional)_**
- [luarocks](https://luarocks.org/) to install rockspecs.
  You can remove `rockspec` from `opts.pkg.sources` to disable this feature.

## 🚀 Getting Started

Check the [documentation website](https://lazy.folke.io/) for more information.
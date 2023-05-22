
---@alias LazyPluginKind "normal"|"clean"|"disabled"

---@class LazyPluginState
---@field loaded? {[string]:string}|{time:number}
---@field installed boolean
---@field tasks? LazyTask[]
---@field dirty? boolean
---@field updated? {from:string, to:string}
---@field is_local boolean
---@field updates? {from:GitInfo, to:GitInfo}
---@field cloned? boolean
---@field kind? LazyPluginKind
---@field dep? boolean True if this plugin is only in the spec as a dependency
---@field cond? boolean
---@field super? LazyPlugin

---@alias PluginOpts table|fun(self:LazyPlugin, opts:table):table?

---@class LazyPluginHooks
---@field init? fun(self:LazyPlugin) Will always be run
---@field deactivate? fun(self:LazyPlugin) Unload/Stop a plugin
---@field config? fun(self:LazyPlugin, opts:table)|true Will be executed when loading the plugin
---@field build? string|fun(self:LazyPlugin)|(string|fun(self:LazyPlugin))[]
---@field opts? PluginOpts

---@class LazyPluginHandlers
---@field event? string[]
---@field cmd? string[]
---@field ft? string[]
---@field keys? (string|LazyKeys)[]
---@field module? false

---@class LazyPluginRef
---@field branch? string
---@field tag? string
---@field commit? string
---@field version? string
---@field pin? boolean
---@field submodules? boolean Defaults to true

---@class LazyPluginBase
---@field [1] string?
---@field name string display name and name used for plugin config files
---@field main? string Entry module that has setup & deactivate
---@field url string?
---@field dir string
---@field enabled? boolean|(fun():boolean)
---@field cond? boolean|(fun():boolean)
---@field optional? boolean If set, then this plugin will not be added unless it is added somewhere else
---@field lazy? boolean
---@field priority? number Only useful for lazy=false plugins to force loading certain plugins first. Default priority is 50
---@field dev? boolean If set, then link to the respective folder under your ~/projects

---@class LazyPlugin: LazyPluginBase,LazyPluginHandlers,LazyPluginHooks,LazyPluginRef
---@field dependencies? string[]
---@field _ LazyPluginState

---@class LazyPluginSpecHandlers
---@field event? string[]|string|fun(self:LazyPlugin, event:string[]):string[]
---@field cmd? string[]|string|fun(self:LazyPlugin, cmd:string[]):string[]
---@field ft? string[]|string|fun(self:LazyPlugin, ft:string[]):string[]
---@field keys? string|string[]|LazyKeys[]|fun(self:LazyPlugin, keys:string[]):(string|LazyKeys)[]
---@field module? false

---@class LazyPluginSpec: LazyPluginBase,LazyPluginSpecHandlers,LazyPluginHooks,LazyPluginRef
---@field dependencies? string|string[]|LazyPluginSpec[]

---@alias LazySpec string|LazyPluginSpec|LazySpecImport|LazySpec[]

---@class LazySpecImport
---@field import string spec module to import
---@field enabled? boolean|(fun():boolean)

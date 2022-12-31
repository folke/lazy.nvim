
---@alias LazyPluginKind "normal"|"clean"

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

---@class LazyPluginHooks
---@field init? fun(LazyPlugin) Will always be run
---@field config? fun(LazyPlugin)|true|table Will be executed when loading the plugin
---@field build? string|fun(LazyPlugin)|(string|fun(LazyPlugin))[]

---@class LazyPluginHandlers
---@field event? string[]
---@field cmd? string[]
---@field ft? string[]
---@field keys? string[]
---@field module? false

---@class LazyPluginRef
---@field branch? string
---@field tag? string
---@field commit? string
---@field version? string
---@field pin? boolean

---@class LazyPluginBase
---@field [1] string?
---@field name string display name and name used for plugin config files
---@field url string?
---@field dir string
---@field enabled? boolean|(fun():boolean)
---@field cond? boolean|(fun():boolean)
---@field lazy? boolean
---@field priority? number Only useful for lazy=false plugins to force loading certain plugins first. Default priority is 50
---@field dev? boolean If set, then link to the respective folder under your ~/projects

---@class LazyPlugin: LazyPluginBase,LazyPluginHandlers,LazyPluginHooks,LazyPluginRef
---@field dependencies? string[]
---@field _ LazyPluginState

---@class LazyPluginSpecHandlers
---@field event? string[]|string
---@field cmd? string[]|string
---@field ft? string[]|string
---@field keys? string|string[]|LazyKeys[]
---@field module? false

---@class LazyPluginSpec: LazyPluginBase,LazyPluginSpecHandlers,LazyPluginHooks,LazyPluginRef
---@field dependencies? string|string[]|LazyPluginSpec[]

---@alias LazySpec string|string[]|LazyPluginSpec[]|LazyPluginSpec[][]

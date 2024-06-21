---@diagnostic disable: undefined-field
local ffi = ffi or require "ffi"
local C = ffi.C

---@format disable-next
local vtable_bind, vtable_thunk = (function()local a=(function()local b=ffi.typeof"void***"return function(c,d,e)return ffi.cast(e,ffi.cast(b,c)[0][d])end end)()local function f(c,d,e,...)local g=a(c,d,ffi.typeof(e,...))return function(...)return g(c,...)end end;local function h(d,e,...)e=ffi.typeof(e,...)return function(c,...)return a(c,d,e)(c,...)end end;return f,h end)()
---@format disable-next
local absolute = (function()return function(a,b,c)if a==nil then return a end;local d=ffi.cast("uintptr_t",a)d=d+b;d=d+ffi.sizeof("int")+ffi.cast("int",ffi.cast("int*",d)[0])d=d+c;return d end end)()

local function create_interface(module_name, interface_name)
    local fnptr = mem.FindPattern(module_name, "4C 8B 0D ?? ?? ?? ?? 4C 8B D2 4C 8B D9")
    if not fnptr then return nil end

    local res = ffi.cast("void*(__cdecl*)(const char*, int*)", fnptr)(interface_name, nil)
    return res ~= nil and res or nil
end

xpcall(function()
    local CPanoramaUIEngine = create_interface("panorama.dll", "PanoramaUIEngine001")

    local CUIEngine = vtable_bind(CPanoramaUIEngine, 13, "void*(__thiscall*)(void*)")()
    local native_IsValidPanelPointer = vtable_bind(CUIEngine, 32, "bool(__thiscall*)(void*, void*)")

    local native_RunScript = vtable_bind(CUIEngine, 81, "void(__thiscall*)(void*, void*, const char*, const char*, uint64_t)")
    local native_GetJavaScriptContextForPanel = vtable_bind(CUIEngine, 89, "void*(__thiscall*)(void*, void*)")
    local native_GetV8Isolate = vtable_bind(CUIEngine, 96, "void*(__thiscall*)(void*)")

    local find_panel = (function()
        local native_GetID = vtable_thunk(11, "const char*(__thiscall*)(void*)")

        local ui_panel_info_t = ffi.typeof [[
            struct {
                char pad[16];
                void* panel;
                char pad[4];
            }
        ]]

        local panel_vec_t = ffi.metatype(ffi.typeof([[
            struct {
                $* m_memory;
                int m_allocation_count;
                int m_grow_size;
                int m_size;
            }
        ]], ui_panel_info_t), {
            __ipairs = function(self)
                return function(vec, i)
                    while i < vec.m_allocation_count do
                        i = i + 1
                        local panel = vec.m_memory[i].panel
                        if native_IsValidPanelPointer(panel) then
                            return i, panel
                        end
                    end
                end, self, -1
            end,
            __pairs = function(self)
                local i = -1
                return function(vec, k)
                    while i < vec.m_allocation_count do
                        i = i + 1
                        local panel = vec.m_memory[i].panel
                        if native_IsValidPanelPointer(panel) then
                            local id = ffi.string(native_GetID(panel))
                            if id ~= nil and id ~= "" then
                                return id, panel
                            end
                        end
                    end
                end, self, nil
            end
        })
        return function(name)
            local names = {}
            for id, panel in pairs(ffi.cast(ffi.typeof("$&", panel_vec_t), ffi.cast("uintptr_t", CUIEngine) + 304)) do
                if not names[id] then
                    if id == name then
                        return panel
                    end
                    names[id] = true
                end
            end
        end
    end)()

    native_RunScript(find_panel "CSGOMainMenu", '$.Msg($.GetContextPanel().id);', "panorama/layout/base_mainmenu.xml", 0)

    print(find_panel "CSGOMainMenu")
end, print)

-- xpcall(function()
--     ffi.cdef [[
--         typedef struct {
--             void* pad;
--             void* panel;
--         } CPanel2D;
--     ]]

--     local mainmenu = ffi.cast("CPanel2D**", absolute(mem.FindPattern("client.dll", "48 83 EC ?? 48 8B 05 ?? ?? ?? ?? 48 8D 15"), 7, 0))[0]

--     local CPanoramaUIEngine = create_interface("panorama.dll", "PanoramaUIEngine001")

--     local CUIEngine = ffi.cast("void**", ffi.cast("uintptr_t", CPanoramaUIEngine) + 0x28)[0]

--     local native_IsValidPanelPointer = vtable_bind(CUIEngine, 32, "bool(__thiscall*)(void*, void*)")
--     local native_RunScript = vtable_bind(CUIEngine, 81, "void(__thiscall*)(void*, void*, const char*, const char*, uint64_t)")
--     local native_GetJavaScriptContextForPanel = vtable_bind(CUIEngine, 89, "void*(__thiscall*)(void*, void*)")
--     local native_GetV8Isolate = vtable_bind(CUIEngine, 96, "void*(__thiscall*)(void*)")

--     print(ffi.cast("void**", ffi.cast("uintptr_t", CUIEngine) + 304)[0])

--     -- for i = 0, map.m_memory.m_allocation_count - 1 do
--     --     print(map.m_memory[i])
--     -- end

--     -- native_RunScript(mainmenu.panel, '$.Msg("Hello, world!");', "panorama/layout/base_mainmenu.xml", 0)

--     -- ffi.cdef [[
--     --     typedef struct {
--     --         void* pad;
--     --         void* panel;
--     --     } CPanel2D;
--     -- ]]

--     -- ffi.cdef [[
--     --     void isolate_enter(void*) asm("?Enter@Isolate@v8@@QEAAXXZ");
--     --     void isolate_exit(void*) asm("?Exit@Isolate@v8@@QEAAXXZ");

--     --     void handle_scope_enter(void*, void*) asm("??0HandleScope@v8@@QEAA@PEAVIsolate@1@@Z");
--     --     void handle_scope_exit(void*) asm("??1HandleScope@v8@@QEAA@XZ");
--     --     void* handle_scope_create_handle(void*, void*) asm("?CreateHandle@HandleScope@v8@@KAPEA_KPEAVIsolate@internal@2@_K@Z");

--     --     void context_enter(void*) asm("?Enter@Context@v8@@QEAAXXZ");
--     --     void context_exit(void*) asm("?Exit@Context@v8@@QEAAXXZ");

--     --     void try_catch_enter(void*, void*) asm("??0TryCatch@v8@@QEAA@PEAVIsolate@1@@Z");
--     --     void try_catch_exit(void*) asm("??1TryCatch@v8@@QEAA@XZ");

--     --     typedef struct value_t {
--     --     } value_t;

--     --     typedef struct local_t {
--     --         value_t* value;
--     --     } local_t;

--     --     local_t* script_run(void*, void*, void*) asm("?Run@Script@v8@@QEAA?AV?$MaybeLocal@VValue@v8@@@2@V?$Local@VContext@v8@@@2@@Z");

--     --     bool value_is_number(void*) asm("?IsNumber@Value@v8@@QEBA_NXZ");
--     --     double value_number_value(void*) asm("?NumberValue@Value@v8@@QEBA?AV?$Maybe@N@2@V?$Local@VContext@v8@@@2@@Z");
--     -- ]]

--     -- local native_CompileScript = ffi.cast("local_t*(__thiscall*)(void*, void*, const char*, const char*)", absolute(mem.FindPattern("panorama.dll", "E8 ?? ?? ?? ?? 48 8B D8 48 83 38 00 75 15"), 1, 0))
--     -- -- local native_RunCompileScript = ffi.cast("local_t*(__thiscall*)(void*, void*, void**)", absolute(mem.FindPattern("panorama.dll", "E8 ?? ?? ?? ?? 4C 8B 7C 24 ?? B0 01"), 1, 0))

--     -- local v8 = ffi.load "v8"

--     -- ffi.metatype("value_t", {
--     --     __index = {
--     --         number_value = v8.value_number_value,
--     --     }
--     -- })

--     -- local isolate_t = ffi.metatype("struct {}", {
--     --     __index = {
--     --         enter = v8.isolate_enter,
--     --         exit = v8.isolate_exit
--     --     }
--     -- })

--     -- local context_t = ffi.metatype("struct {}", {
--     --     __index = {
--     --         enter = v8.context_enter,
--     --         exit = v8.context_exit
--     --     }
--     -- })

--     -- local try_catch_t = ffi.metatype("struct {}", {
--     --     __index = {
--     --         enter = v8.try_catch_enter,
--     --         exit = v8.try_catch_exit
--     --     }
--     -- })

--     -- local handle_scope_t = ffi.metatype("struct {}", {
--     --     __index = {
--     --         enter = v8.handle_scope_enter,
--     --         exit = v8.handle_scope_exit,
--     --         create_handle = v8.handle_scope_create_handle
--     --     }
--     -- })

--     -- local javascript_context = native_GetJavaScriptContextForPanel(mainmenu.panel)

--     -- local scope = handle_scope_t()
--     -- local try_catch = try_catch_t()

--     -- local isolate = ffi.cast(ffi.typeof("$*", isolate_t), native_GetV8Isolate())
--     -- isolate:enter()
--     -- scope:enter(isolate)

--     -- local context = ffi.cast(ffi.typeof("$*", context_t), handle_scope_t.create_handle(isolate, ffi.cast("void***", javascript_context)[0][0]))
--     -- context:enter()

--     -- try_catch:enter(isolate)
--     -- local compiled = native_CompileScript(CUIEngine, mainmenu.panel, string.format("(function(){%s})()", '$.Msg("CompileScript");'), "")
--     -- try_catch:exit()

--     -- try_catch:enter(isolate)
--     -- local unk = ffi.new "char[8]"
--     -- local val = v8.script_run(compiled.value, unk, context)
--     -- try_catch:exit()

--     -- print("val", val)
--     -- -- print(ffi.cast("value_t*", val):number_value())

--     -- context:exit()
--     -- scope:exit()
--     -- isolate:exit()
-- end, print)

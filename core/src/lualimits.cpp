/*
 * qBittorrent Neo — memory cap for the Lua states of qBittorrent 5.3's
 * plugins engine.
 *
 * Upstream's Plugin::load() creates each plugin's state with
 * luaL_newstate(), whose allocator has no limit, so a plugin could exhaust
 * the app's memory (`string.rep("x", 2^40)`, an endless table). Without
 * editing qbittorrent/, core/CMakeLists.txt compiles that one file with
 * `luaL_newstate` defined as `qbtneo_luaL_newstate`, and this function
 * returns the usual state with a counting allocator on top: past
 * PLUGIN_MEMORY_LIMIT an allocation fails and Lua raises "not enough
 * memory" in the plugin, which upstream logs like any other plugin error.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <cstdlib>
#include <new>

#include <lua/lua.hpp>

namespace
{
    // As in qBit NeoRS (crates/qbt-core/src/plugins/runtime.rs).
    constexpr std::size_t PLUGIN_MEMORY_LIMIT = 16 * 1024 * 1024;

    // One per state, never freed: the allocator cannot tell lua_close()'s
    // last call apart, and plugin states are created only when the engine
    // starts or a plugin is installed or updated.
    struct Budget
    {
        std::size_t used = 0;
    };

    // lua_Alloc contract: `ptr == nullptr` means a new block (then `osize`
    // is a type tag, not a size); `nsize == 0` frees; shrinking must not fail.
    void *cappedAlloc(void *ud, void *ptr, const std::size_t osize, const std::size_t nsize)
    {
        auto *budget = static_cast<Budget *>(ud);
        const std::size_t oldSize = ptr ? osize : 0;

        // Clamped: the starting count comes from Lua's own statistics.
        const std::size_t usedWithoutBlock = (budget->used > oldSize) ? (budget->used - oldSize) : 0;

        if (nsize == 0)
        {
            std::free(ptr);
            budget->used = usedWithoutBlock;
            return nullptr;
        }

        if ((nsize > oldSize) && ((usedWithoutBlock + nsize) > PLUGIN_MEMORY_LIMIT))
            return nullptr;

        void *block = std::realloc(ptr, nsize);
        if (block)
            budget->used = usedWithoutBlock + nsize;
        return block;
    }
}

extern "C" lua_State *qbtneo_luaL_newstate(void)
{
    // Not renamed here: this is Lua's own luaL_newstate (panic and warning
    // handlers set up as usual).
    lua_State *luaState = luaL_newstate();
    if (!luaState)
        return nullptr;

    auto *budget = new (std::nothrow) Budget;
    if (!budget)
    {
        lua_close(luaState);
        return nullptr;
    }

    // The blocks allocated so far are freed through cappedAlloc later, so
    // the count starts at what the state already uses.
    budget->used = (static_cast<std::size_t>(lua_gc(luaState, LUA_GCCOUNT)) * 1024)
        + static_cast<std::size_t>(lua_gc(luaState, LUA_GCCOUNTB));
    lua_setallocf(luaState, cappedAlloc, budget);
    return luaState;
}

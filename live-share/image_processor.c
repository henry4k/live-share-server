#include <assert.h>
#include <string.h> // NULL
#include <stdlib.h> // atexit
#include <lua.h> // lua*
#include <lauxlib.h> // luaL*
#include <vips/vips.h>

#if defined(_MSC_VER)
    #define EXPORT __declspec(dllexport)
#else
    #define EXPORT
#endif

//#define THROW_ERRORS

static int report_vips_error(lua_State* l)
{
    lua_pushnil(l);
    lua_pushstring(l, vips_error_buffer());
    vips_error_clear();
#if defined(THROW_ERRORS)
    return lua_error(l);
#else
    return 2;
#endif
}

static int lua_vips_init(lua_State* l)
{
    const char* argv0 = luaL_checkstring(l, 1);
    if(VIPS_INIT(argv0))
        return report_vips_error(l);
    atexit(vips_shutdown);
    return 0;
}

static int lua_vips_thread_shutdown(lua_State* l)
{
    vips_thread_shutdown();
    return 0;
}

static int lua_vips_leak_set(lua_State* l)
{
    vips_leak_set(lua_toboolean(l, 1));
    return 0;
}

static int lua_vips_version_string(lua_State* l)
{
    lua_pushstring(l, vips_version_string());
    return 1;
}

EXPORT int luaopen_share_image_processor(lua_State* l)
{
    const luaL_Reg reg[] =
    {
        {"init", lua_vips_init},
        {"thread_shutdown", lua_vips_thread_shutdown},
        {"leak_set", lua_vips_leak_set},
        {"version_string", lua_vips_version_string},
        {NULL, NULL}
    };

    lua_newtable(l);
    luaL_setfuncs(l, reg, 0);
    return 1;
}

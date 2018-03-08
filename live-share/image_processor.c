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

static int check_vips_access_from_lua(lua_State* l, int arg)
{
    static const char* options =
    {
        "random",
        "sequential",
        "sequential_unbuffered"
    };
    return luaL_checkoption(l, arg, NULL, options);
}

static VipsImage* check_vips_image_from_lua(lua_State* l, int arg)
{
    //return (VipsImage*)luaL_checkudata(l, arg, "VipsImage");

    if(!lua_islightuserdata(l, arg))
    {
        luaL_error("invalid parameter type");
        return NULL;
    }
    return (VipsImage*)lua_touserdata(l, arg);
}

static int lua_vips_image_unref(lua_State* l)
{
    g_object_unref(check_vips_image_from_lua(l, 1));
    return 0;
}

static int lua_vips_image_new_from_file(lua_State* l)
{
    const char* name = luaL_checkstring(l, 1);
    VipsImage* image = vips_image_new_from_file(name);
    lua_pushlightuserdata(l, image);
    return 1;
}

static int lua_vips_image_write_to_file(lua_State* l)
{
    VipsImage* image = check_vips_image_from_lua(l, 1);
    const char* name = luaL_checkstring(l, 2);
    vips_image_write_to_file(image, name);
    return 0;
}

static int lua_vips_image_get_properties(lua_State* l)
{
    // check_vips_image_from_lua()

    //lua_createtable(l, 0, );
    // ...
    return 1;
}

EXPORT int luaopen_share_image_processor(lua_State* l)
{
    //luaL_newmetatable(l, "VipsImage");
    //lua_pushcfunction(l, __gc_callback__);
    //lua_setfield(l, -2, "__gc");
    //lua_pop(l, 1); // pop metatable

    //void* data = lua_newuserdata(l, __size__);
    //luaL_getmetatable(l, "VipsImage");
    //assert(lua_istable(l, -1));
    //lua_setmetatable(l, -2);

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

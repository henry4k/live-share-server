#include <assert.h>
#include <string.h> // NULL
#include <stdbool.h>
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

#if defined(MAX)
    #warning "MAX macro has already been defined somewhere else - what the fuck."
    #undef MAX
#endif
#define MAX(A,B) ((A) > (B) ? (A) : (B))

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

static int ls_lua_init(lua_State* l)
{
    if(VIPS_INIT(luaL_checkstring(l, 1)))
        return report_vips_error(l);
    atexit(vips_shutdown);
    lua_pushboolean(l, true);
    return 1;
}

static int ls_lua_thread_shutdown(lua_State* l)
{
    vips_thread_shutdown();
    lua_pushboolean(l, true);
    return 1;
}

static int ls_lua_version(lua_State* l)
{
    lua_pushstring(l, vips_version_string());
    return 1;
}

static int ls_lua_process(lua_State* l)
{
    const char* source_file = luaL_checkstring(l, 1);
    const char* target_file = luaL_checkstring(l, 2);
    const int   target_size = luaL_checkinteger(l, 3);

    // Extract metadata:
    VipsImage* source_image = vips_image_new_from_file(source_file, NULL);
    if(!source_image)
        return report_vips_error(l);
    const int source_width  = vips_image_get_width(source_image);
    const int source_height = vips_image_get_height(source_image);
    g_object_unref(source_image);

    // Calculate thumbnail dimensions:
    int target_width;
    if(source_width > source_height)
        target_width = target_size * source_width / source_height;
    else
        target_width = target_size * source_height / source_width;

    // Generate thumbnail:
    VipsImage* target_image;
    if(vips_thumbnail(source_file,
                      &target_image,
                      target_width,
                      "size", VIPS_SIZE_DOWN, // only shrink image
                      NULL))
        return report_vips_error(l);
    if(vips_image_write_to_file(target_image, target_file, NULL))
        return report_vips_error(l);
    g_object_unref(target_image);

    // Create metadata table:
    lua_createtable(l, 0, 2); // 2 keys
    lua_pushinteger(l, source_width);
    lua_setfield(l, -2, "width");
    lua_pushinteger(l, source_height);
    lua_setfield(l, -2, "height");
    return 1;
}

static void* image_property_callback(VipsImage* image,
                                     const char* name,
                                     GValue* value,
                                     void* context)
{
    lua_State* l = (lua_State*)context;
    switch(G_VALUE_TYPE(value))
    {
        case G_TYPE_INT:
            lua_pushinteger(l, (LUA_INTEGER)g_value_get_int(value));
            break;

        case G_TYPE_DOUBLE:
            lua_pushnumber(l, (LUA_NUMBER)g_value_get_double(value));
            break;

        case G_TYPE_STRING:
            lua_pushstring(l, g_value_get_string(value));
            break;

        default:
            lua_pushstring(l, "--unknown-type--"); // TODO
    }
    lua_setfield(l, -2, name);
    return NULL;
}

static int ls_lua_get_metadata(lua_State* l)
{
    const char* file = luaL_checkstring(l, 1);
    VipsImage* image = vips_image_new_from_file(file, NULL);
    if(!image)
        return report_vips_error(l);
    lua_newtable(l);
    vips_image_map(image, image_property_callback, l);
    g_object_unref(image);
    return 1;
}

EXPORT int luaopen_share_media_image_processor(lua_State* l)
{
    const luaL_Reg reg[] =
    {
        {"init", ls_lua_init},
        {"thread_shutdown", ls_lua_thread_shutdown},
        {"version", ls_lua_version},
        {"process", ls_lua_process},
        {"get_metadata", ls_lua_get_metadata},
        {NULL, NULL}
    };

    lua_newtable(l);
    luaL_setfuncs(l, reg, 0);
    return 1;
}

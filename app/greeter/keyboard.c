/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2013 Long Wei
 *
 * Author:      Long Wei <yilang2007lw@gmail.com>
 *              bluth <yuanchenglu001@gmail.com>
 * Maintainer:  Long Wei <yilang2007lw@gamil.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/

#include <gtk/gtk.h>
#include "keyboard.h"

GList* g_layouts = NULL;
GSettings* s_layout;
gchar** layouts = NULL;
#define LAYOUT_SCHEMA_ID "com.deepin.dde.keyboard"
#define LAYOUT_KEY "user-layout-list"

void init_keyboard()
{
    s_layout = g_settings_new(LAYOUT_SCHEMA_ID);
}

LightDMLayout*
find_layout_by_des(gchar *des)
{
    LightDMLayout *ret = NULL;
    guint i;

    if (g_layouts == NULL) {
        g_layouts = lightdm_get_layouts ();
    }

    for (i = 0; i < g_list_length (g_layouts); i++) {
        LightDMLayout *layout = (LightDMLayout *) g_list_nth_data (g_layouts, i);

        if (layout != NULL) {
            const gchar *layout_des = g_strdup (lightdm_layout_get_description (layout));
            if (g_strcmp0 (des, layout_des) == 0) {
                ret = layout;

            } else {
                continue;
            }
        } else {
            continue;
        }
    }

    return ret;
}

LightDMLayout*
find_layout_by_name(gchar *name)
{
    LightDMLayout *ret = NULL;
    guint i;

    if (g_layouts == NULL) {
        g_layouts = lightdm_get_layouts ();
    }

    for (i = 0; i < g_list_length (g_layouts); i++) {
        LightDMLayout *layout = (LightDMLayout *) g_list_nth_data (g_layouts, i);

        if (layout != NULL) {
            const gchar *layout_name = g_strdup (lightdm_layout_get_name (layout));
            if (g_strcmp0 (name, layout_name) == 0) {
                ret = layout;

            } else {
                continue;
            }
        } else {
            continue;
        }
    }

    return ret;
}


JS_EXPORT_API
JSObjectRef greeter_get_layouts ()
{
    JSObjectRef array = json_array_create ();

    guint i;

    //if (layouts == NULL) {
    //    layouts = g_settings_get_strv(s_layout,LAYOUT_KEY);
    //}
    layouts = g_settings_get_strv(s_layout,"user-layout-list");
    guint len = g_strv_length(layouts);
    g_message("layouts len:%d",len);
    for (i = 0; i < len; i++) {
        gchar* dest = NULL;
        g_utf8_strncpy(dest,layouts[i],(gsize)(g_utf8_strlen(layouts[i],0)-1));
        g_message("keyboard layout:%d:=========%s===========",i,dest);
        LightDMLayout *layout = find_layout_by_name(dest);
        const gchar* name = g_strdup(lightdm_layout_get_description(layout));
        g_free(dest);
        json_array_insert (array, i, jsvalue_from_cstr (get_global_context (), g_strdup (name)));
    }

    return array;
}

JS_EXPORT_API
gchar* greeter_get_current_layout ()
{
    LightDMLayout *layout  = lightdm_get_layout();
    gchar *des = g_strdup (lightdm_layout_get_description (layout));
    return des;
}

JS_EXPORT_API
void greeter_set_layout (gchar* des)
{
    LightDMLayout *layout = find_layout_by_des(des);
    lightdm_set_layout(layout);
}

JS_EXPORT_API
const gchar* greeter_get_short_description (gchar* name)
{
    LightDMLayout *layout = find_layout_by_name(name);
    const gchar* des = lightdm_layout_get_short_description(layout);
    return des;
}

JS_EXPORT_API
const gchar* greeter_get_description (gchar* name)
{
    LightDMLayout *layout = find_layout_by_name(name);
    const gchar* des = lightdm_layout_get_description(layout);
    return des;
}

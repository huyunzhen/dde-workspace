/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 *Author:      bluth <yuanchenglu@linuxdeepin.com>
 *Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
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

#ifndef __TEMPLATES_H__
#define __TEMPLATES_H__

#include <glib.h>
#include <gio/gio.h>
#include <glib/gstdio.h>
#include <stdio.h>
#include <string.h>

char *   nautilus_get_xdg_dir                        (const char *type);
gboolean nautilus_should_use_templates_directory     (void);
char *   nautilus_get_templates_directory            (void);
char *   nautilus_get_templates_directory_uri        (void);
void     nautilus_create_templates_directory         (void);

#endif
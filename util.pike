//
//
//  util.pike: utility functions
//
//  Copyright 2002 by Bill Welliver <hww3@riverweb.com>
//
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
//  USA.
//
//

#include "config.h"

constant cvs_version="$Id: util.pike,v 1.1.1.1 2002-06-28 20:36:25 hww3 Exp $";

mapping loadPreferences()
{
  mapping prefs=([]);

  string f="";
  if(file_stat("./" + APP_CONFIGNAME + "_defaults.conf"))
    f+=Stdio.read_file("./" + APP_CONFIGNAME + "_defaults.conf");
  if(file_stat("/etc/" + APP_CONFIGNAME + ".conf"))
    f+=Stdio.read_file("/etc/" + APP_CONFIGNAME + ".conf");
  if(file_stat(getenv("HOME") + "/." + APP_CONFIGNAME + ".conf"))
    f+=Stdio.read_file(getenv("HOME") + "/." + APP_CONFIGNAME + ".conf");

  prefs=.Config.read(f);
  
  return prefs;
}

void openError(string msg)
{
  object errMsg=Gnome.MessageBox(msg,
    Gnome.MessageBoxError, Gnome.StockButtonCancel);    
  errMsg->set_usize(325, 175);
  errMsg->run();
}


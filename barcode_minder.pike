#!/usr/local/bin/pike -M.
//
//
//  barcode_minder.pike: A GTK+ based barcode scanner tool
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

constant cvs_version="$Id: barcode_minder.pike,v 1.1.1.1 2002-06-28 20:36:25 hww3 Exp $";

#include "config.h"

inherit "util.pike";

object win,status;
int cont;

object displaylabel, devicelabel;

object dpy,xt,serial;
int XConnected,SerialConnected;

mapping preferences=([]);

int main(int argc, array argv) {

 if(file_stat( getenv("HOME")+"/.pgtkrc" ))
    GTK.parse_rc( cpp(Stdio.read_bytes(getenv("HOME")+"/.pgtkrc")) );

write("Starting " + APP_NAME+ " " + APP_VERSION + "...\n");

// let's load the preferences and command line options.

preferences=loadPreferences();

argv=parseCommandLine(argv);

// start up the ui...

Gnome.init(APP_WINNAME, APP_VERSION , argv);
win=Gnome.App(APP_NAME, APP_NAME);
win->set_usize(430,140);

setupStatus();

setupApp();

win->signal_connect(GTK.delete_event, appQuit, 0);
win->show();

return -1;
}

void appQuit()

{
  _exit(0);
}

void openAbout()
{
  object aboutWindow;
  aboutWindow = Gnome.About(APP_NAME,
				APP_VERSION, "(c) " + APP_AUTHOR + " " + APP_YEAR,
				({APP_AUTHOR}),
				APP_DESCRIPTION,
				"icons/spiral.png");
  aboutWindow->show();
  return;
 }

void openPreferences()
{
  object aboutWindow;
  aboutWindow = Gnome.About(APP_NAME,
				APP_VERSION, "(c) Bill Welliver 2002",
				({"Bill Welliver", ""}),
				"Manage your LDAP directory with style.",
				"icons/spiral.png");
  aboutWindow->show();
  return;
 }

void setupStatus()
{
  status=GTK.Statusbar();
  status->set_usize(0,19);
  cont=status->get_context_id("Main Application");
  status->push(cont, APP_NAME + " Ready.");
  win->set_statusbar(status);

}

void pushStatus(string stat)
{  
//  status->pop(cont);
  status->push(cont, stat);
  call_out(popStatus, 5);
}

void popStatus()
{  
  status->pop(cont);
//  status->push(cont, stat);

}


array parseCommandLine(array argv)
{

  string target=Getopt.find_option(argv, "t", "target", 
    "BARCODE_TARGET", getenv("DISPLAY"));
  if(!preferences->display) preferences->display=([]);
  preferences->display->target=target;

  string barcode_device="/dev/term/a";
  if(preferences->serial && preferences->serial->device)
    barcode_device=preferences->serial->device;

  string device=Getopt.find_option(argv, "d", "device", 
    "BARCODE_DEVICE", barcode_device);
  if(!preferences->display) preferences->serial=([]);
  preferences->serial->device=device;

  argv-=({0});
  return argv;
}

void setupApp()
{

  displaylabel=GTK.Label("");
  devicelabel=GTK.Label("");
  
  object vbox=GTK.Vbox(0,2);
  
  object resetbutton=GTK.Button("Reset");

  resetbutton->show();

  vbox->show();
  displaylabel->show();
  devicelabel->show();
  
  object frame1=GTK.Frame("Display")->add(displaylabel)->show();
  object frame2=GTK.Frame("Serial Port")->add(devicelabel)->show();

  object box1=GTK.Vbox(1,4)->show();
  object box3=GTK.Hbox(0,4)->show();
  object box2=GTK.Hbox(1,4)->show();

  box1->pack_start(frame1, 1,1,4);
  box1->pack_start(frame2, 1,1,4);
  box2->pack_start(box1, 1,1,4);
  box3->pack_start(resetbutton, 1,0,4);

  vbox->pack_start(box2, 1,0,4);
  vbox->pack_end(box3, 0 ,1,4);

  resetbutton->signal_connect(GTK.button_press_event, doReset);
  
  win->set_contents(vbox);

  setupDisplay(); 
  setupSerial();

}

void doReset()
{
  pushStatus("Communications Reset");
  shutdownDisplay();
  shutdownSerial();
  setupDisplay();
  setupSerial();
}

void shutdownDisplay()
{
  if(dpy)
  {
    dpy->close();
    dpy=0;
    xt=0;
  }  

}

void shutdownSerial()
{

  if(serial)
  {
     serial->close();
     serial=0;
  }

}

void setupDisplay()
{

  string display;
  
  if(preferences && preferences->display && preferences->display->target)
    display=(preferences->display->target);
  else display=getenv("DISPLAY");

  dpy=Protocols.X.Xlib.Display();
  if(!dpy->open(display))
  {
    displaylabel->set_text(display + " Not OK");
    XConnected=0;
  }
  else
  {
    xt=Protocols.X.Extensions.XTEST();
    if(catch(xt->init(dpy)))
    {
      displaylabel->set_text(display + " Not OK");
      XConnected=0;
    }
    else
    {
      displaylabel->set_text(display + " OK");
      XConnected=1;
    }
  }
}

void setupSerial()
{

  string device;

  if(preferences->serial->device)
    device=preferences->serial->device;
  else device="/dev/term/a";

  if(catch(serial=Stdio.File(device, "rw")))
  {
    devicelabel->set_text(device + ": Not OK");
    SerialConnected=0;

  }
  else
  {
    serial->set_nonblocking();
    serial->set_read_callback(barcode_read_callback);
    devicelabel->set_text(device + ": OK");
    SerialConnected=1;
  }
}

void barcode_read_callback(object id, string s)
{

  if(sizeof(s)==1 && s=="\n") return;


  if(XConnected)
  {
    pushStatus("Received Barcode Data: " + s);
    foreach(s/"", string c)
    {
    if(c=="\n") c="XK_Return";
    int keys=Protocols.X.KeySyms.LookupCharacter(c);
    int keycode;
    if(catch(keycode=Protocols.X.KeySyms.LookupKeycode(keys, dpy)))
    {
      pushStatus("X Communication Error.");
      doReset();
      return;
    }
  
      if(keycode>-1)
      {
        xt->XTestFakeInput("KeyPress", 64, 0,0,0,0);
        xt->XTestFakeInput("KeyPress", keycode, 0,0,0,0);
        xt->XTestFakeInput("KeyRelease", keycode, 0,0,0,0);
        xt->XTestFakeInput("KeyRelease", 64, 0,0,0,0);
      }
    }
  }
  else
    pushStatus(("Received Barcode Data: " + s + ", not sent.")-"\n");

}

object xt,dpy,serial;

int main()
{
  
  dpy=Protocols.X.Xlib.Display();

  dpy->open(getenv("DISPLAY"));

  xt=Protocols.X.Extensions.XTEST();
 
  xt->init(dpy);

  serial=Stdio.File("/tmp/SUNWut/units/IEEE802.080020f8a3ab/dev/term/Quatech.8020-1a", "rw");
  serial->set_nonblocking();
  serial->set_read_callback(read_callback);

  return -1;
}

void read_callback(object id, string s)
{

  werror("got data: " + s + "\n");
  if(sizeof(s)==1 && s=="\n") return;
  foreach(s/"", string c){
  if(c=="\n") c="XK_Return";
  int keys=Protocols.X.KeySyms.LookupCharacter(c);
  int keycode=Protocols.X.KeySyms.LookupKeycode(keys, dpy);
  
  if(keycode>-1){
    xt->XTestFakeInput("KeyPress", 64, 0,0,0,0);
    xt->XTestFakeInput("KeyPress", keycode, 0,0,0,0);
    xt->XTestFakeInput("KeyRelease", keycode, 0,0,0,0);
    xt->XTestFakeInput("KeyRelease", 64, 0,0,0,0);
    }
  }

  }

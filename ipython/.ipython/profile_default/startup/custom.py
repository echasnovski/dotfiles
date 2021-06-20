from IPython import get_ipython

ip = get_ipython()

if getattr(ip, "pt_app", None):
    app = ip.pt_app.app

    # Modify timeout length (in seconds): time to wait after pressing <Esc> for
    # another key pressing. Very useful to reduce delay when going in Normal
    # mode under "vim" editing mode.
    app.ttimeoutlen = 0.05
    # This shouldn't be too small, as it is used when inserting operator
    # sequence in normal mode
    app.timeoutlen = 0.25

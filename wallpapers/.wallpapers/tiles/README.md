# Tiling wallpaper patterns

This directory contains `svg` files designed to be used as tiling block for patterned display wallpaper. They are very light and (subjectively) pleasant to use. They are taken from [hero patterns](https://heropatterns.com/) and manually modified to have consistent content. They are basically a unicolored patterns without background which should be first converted to "real" image (like `png`) and then used with something which supports image tiling (like [feh](https://feh.finalrewind.org/)). Initial customization of line color is done for [ayu-mirage](https://github.com/ayu-theme/ayu-colors) them.

## Instructions

Currently preferred usage:

- Customize to your liking:
    - Line color is defined with `fill="#RRGGBB"` part inside every `svg` file. Find and replace this with your favorite method.
    - Line opacity is defined with `fill-opacity="x.xx"` part inside every `svg` file. Find and replace this with your favorite method.
    - Background can be customized during conversion to `png`.
- Convert all `svg` files to `png` and place them in separate 'png' directory. Convenient tool for this is [ImageMagick](https://imagemagick.org/index.php) which enables bulk conversion (change background color to your liking):
    ```bash
    mkdir -p png
    magick -background "#081823" 'svg/*.svg' -set filename:fn '%[basename]' 'png/%[filename:fn].png'
    ```
- Make image to be background with tiling option. Using `feh`:
    ```bash
    feh --bg-tile png/<file_name>.png
    ```

    To randomly pick image from directory:
    ```bash
    feh --bg-tile --randomize png
    ```

    To automatically randomly change background every 900 seconds:
    ```bash
    while true
    do
        feh --bg-tile --randomize <path_to_parent>/png
        sleep 900
    done
    ```

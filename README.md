# image-term

A terminal-based image viewer written in [V](https://vlang.io/) that renders images as colored ASCII mosaics.
Based on the blog post [Convert an Image into Colourful Ascii Art](https://linyunliu.com/blogs/convert-an-image-into-colourful-ascii-art/).

![image-term](/docs/ascii-veasel.png)

## How it works

image-term loads an image, resizes it to fit your terminal dimensions, and renders it using colored `@` characters.

It automatically:

- Detects terminal size and scales the image to fit
- Corrects for a terminal character aspect ratio (characters are taller than they are wide)
- Averages pixel colors within grid blocks for accurate color representation
- Supports grayscale, RGB, and RGBA images via [stb_image](https://github.com/nothings/stb)

## Building

```sh
v -o image-term .
```

## Usage

```sh
./image-term <image-path>
```

### Supported formats

Any format supported by stb_image: JPEG, PNG, BMP, GIF, PSD, TGA, HDR, PIC, PNM.

## Example

```sh
./image-term assets/54754230613_c896220d22_c.jpg
```

## Requirements

- [V compiler](https://vlang.io/)
- A terminal with true color (24-bit) support

import stbi
import term
import math
import os

struct Color {
	r u8
	g u8
	b u8
}

struct Dimensions {
	grid_size int
	width     int
	height    int
}

const height_factor = 0.5 // terminal character aspect ratio correction
const mosaic_char = '@'

fn main() {
	// check for command line arg
	path := if os.args.len > 1 {
		os.args[1]
	} else {
		eprintln('Usage: image-term <image-path>')
		return
	}
	// Load image
	img := stbi.load(path) or {
		eprintln('Failed to load image: ${err}')
		return
	}
	defer { img.free() }

	// Get terminal size
	term_cols, term_rows := term.get_terminal_size()

	dims := compute_dimensions(img.width, img.height, term_cols, term_rows)

	// Resize image
	resized := resize_image(img, dims.width, dims.height)

	term.clear()
	term.set_cursor_position(term.Coord{0, 0})

	// Render mosaic using grid_size blocks
	for gy in 0 .. dims.height / dims.grid_size {
		for gx in 0 .. dims.width / dims.grid_size {
			color := average_color_block(resized, gx * dims.grid_size, gy * dims.grid_size,
				dims.grid_size, dims.grid_size, dims.width, dims.height)
			print_color_block(color)
		}
		println('\x1b[0m') // reset color after each line
	}
}

// compute_dimensions Compute grid size and resized image dimensions to fit the terminal
fn compute_dimensions(img_w int, img_h int, term_cols int, term_rows int) Dimensions {
	grid_x := int(math.ceil(f32(img_w) / f32(term_cols)))
	grid_y := int(math.ceil(f32(img_h) / f32(term_rows)))
	grid_size := if grid_x > grid_y { grid_x } else { grid_y }

	aspect_ratio := f32(img_h) / f32(img_w)
	mut width := term_cols * grid_size
	mut height := int(aspect_ratio * f32(width) * height_factor)

	if height > term_rows * grid_size {
		height = term_rows * grid_size
		width = int(f32(height) / (aspect_ratio * height_factor))
	}

	return Dimensions{
		grid_size: grid_size
		width:     width
		height:    height
	}
}

// resize_image Resize image using nearest-neighbor
fn resize_image(img stbi.Image, new_w int, new_h int) []Color {
	// Convert raw pointer data to safe V slice
	data := unsafe { img.data.vbytes(int(img.width * img.height * img.nr_channels)) }

	mut result := []Color{len: new_w * new_h}
	for y in 0 .. new_h {
		for x in 0 .. new_w {
			src_x := int(f32(x) * f32(img.width) / f32(new_w))
			src_y := int(f32(y) * f32(img.height) / f32(new_h))
			idx := (src_y * img.width + src_x) * img.nr_channels
			if idx + img.nr_channels <= data.len {
				r := data[idx]
				g := if img.nr_channels > 1 { data[idx + 1] } else { u8(0) }
				b := if img.nr_channels > 2 { data[idx + 2] } else { u8(0) }
				result[y * new_w + x] = Color{r, g, b}
			}
		}
	}
	return result
}

// average_color_block Compute average color in a rectangular block of pixels
fn average_color_block(img []Color, start_x int, start_y int, w int, h int, img_w int, img_h int) Color {
	mut sum_r := 0
	mut sum_g := 0
	mut sum_b := 0
	mut count := 0

	end_x := if start_x + w < img_w { start_x + w } else { img_w }
	end_y := if start_y + h < img_h { start_y + h } else { img_h }

	for y in start_y .. end_y {
		for x in start_x .. end_x {
			c := img[y * img_w + x]
			sum_r += int(c.r)
			sum_g += int(c.g)
			sum_b += int(c.b)
			count++
		}
	}

	if count == 0 {
		return Color{0, 0, 0}
	}

	return Color{
		r: u8(sum_r / count)
		g: u8(sum_g / count)
		b: u8(sum_b / count)
	}
}

// print_color_block Print colored character
fn print_color_block(c Color) {
	print(term.rgb(c.r, c.g, c.b, mosaic_char))
}

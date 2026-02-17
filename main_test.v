module main

// test_compute_dimensions_square_image_fits_terminal Test square image that fits within terminal
fn test_compute_dimensions_square_image_fits_terminal() {
	// 80x80 image in a 80x24 terminal
	dims := compute_dimensions(80, 80, 80, 24)
	assert dims.grid_size >= 1
	assert dims.width > 0
	assert dims.height > 0
	// Resized dimensions should not exceed terminal grid
	assert dims.width / dims.grid_size <= 80
	assert dims.height / dims.grid_size <= 24
}

// test_compute_dimensions_wide_image Test wide (landscape) image
fn test_compute_dimensions_wide_image() {
	// 1920x1080 image in 80x24 terminal
	dims := compute_dimensions(1920, 1080, 80, 24)
	assert dims.grid_size == 45 // ceil(1920/80)=24, ceil(1080/24)=45 -> max is 45
	assert dims.width > 0
	assert dims.height > 0
	assert dims.width / dims.grid_size <= 80
	assert dims.height / dims.grid_size <= 24
}

// test_compute_dimensions_tall_image Test tall (portrait) image
fn test_compute_dimensions_tall_image() {
	// 600x1200 image in 80x24 terminal
	dims := compute_dimensions(600, 1200, 80, 24)
	assert dims.grid_size >= 1
	assert dims.width > 0
	assert dims.height > 0
	assert dims.width / dims.grid_size <= 80
	assert dims.height / dims.grid_size <= 24
}

// test_compute_dimensions_small_image Test image smaller than terminal
fn test_compute_dimensions_small_image() {
	// 10x10 image in 80x24 terminal
	dims := compute_dimensions(10, 10, 80, 24)
	assert dims.grid_size == 1 // image fits easily, grid_size should be 1
	assert dims.width > 0
	assert dims.height > 0
}

// test_compute_dimensions_preserves_aspect_ratio Test that aspect ratio is approximately preserved
fn test_compute_dimensions_preserves_aspect_ratio() {
	// 1000x500 image (2:1 aspect ratio) in 80x24 terminal
	dims := compute_dimensions(1000, 500, 80, 24)
	// With height_factor=0.5, effective aspect is 500/1000 * 0.5 = 0.25
	// So height should be roughly width * 0.25
	effective_ratio := f32(dims.height) / f32(dims.width)
	expected_ratio := f32(500) / f32(1000) * 0.5
	diff := if effective_ratio > expected_ratio {
		effective_ratio - expected_ratio
	} else {
		expected_ratio - effective_ratio
	}
	assert diff < 0.05, 'aspect ratio not preserved: got ${effective_ratio}, expected ~${expected_ratio}'
}

// test_compute_dimensions_height_clamping Test that height gets clamped when it would exceed terminal
fn test_compute_dimensions_height_clamping() {
	// Very tall image: 100x2000 in 80x24 terminal
	dims := compute_dimensions(100, 2000, 80, 24)
	assert dims.height <= 24 * dims.grid_size, 'height ${dims.height} exceeds terminal grid ${24 * dims.grid_size}'
}

// test_average_color_block_single_pixel Test average_color_block with a single pixel
fn test_average_color_block_single_pixel() {
	img := [Color{255, 0, 0}]
	result := average_color_block(img, 0, 0, 1, 1, 1, 1)
	assert result.r == 255
	assert result.g == 0
	assert result.b == 0
}

// test_average_color_block_uniform_color Test average_color_block with uniform color block
fn test_average_color_block_uniform_color() {
	blue := Color{0, 0, 255}
	img := []Color{len: 9, init: blue}
	result := average_color_block(img, 0, 0, 3, 3, 3, 3)
	assert result.r == 0
	assert result.g == 0
	assert result.b == 255
}

// test_average_color_block_mixed_colors Test average_color_block averages correctly across mixed colors
fn test_average_color_block_mixed_colors() {
	// 2x2 image: red, green, blue, white
	img := [
		Color{255, 0, 0},
		Color{0, 255, 0},
		Color{0, 0, 255},
		Color{255, 255, 255},
	]
	result := average_color_block(img, 0, 0, 2, 2, 2, 2)
	// averages: r=(255+0+0+255)/4=127, g=(0+255+0+255)/4=127, b=(0+0+255+255)/4=127
	assert result.r == 127
	assert result.g == 127
	assert result.b == 127
}

// test_average_color_block_sub_region Test average_color_block with a sub-region of a larger image
fn test_average_color_block_sub_region() {
	// 4x4 image, all black except a 2x2 white block at (2,2)
	mut img := []Color{len: 16, init: Color{0, 0, 0}}
	img[2 * 4 + 2] = Color{200, 200, 200}
	img[2 * 4 + 3] = Color{200, 200, 200}
	img[3 * 4 + 2] = Color{200, 200, 200}
	img[3 * 4 + 3] = Color{200, 200, 200}

	// Average the top-left 2x2 block (all black)
	result_black := average_color_block(img, 0, 0, 2, 2, 4, 4)
	assert result_black.r == 0
	assert result_black.g == 0
	assert result_black.b == 0

	// Average the bottom-right 2x2 block (all 200)
	result_grey := average_color_block(img, 2, 2, 2, 2, 4, 4)
	assert result_grey.r == 200
	assert result_grey.g == 200
	assert result_grey.b == 200
}

// test_average_color_block_clamps_to_bounds Test average_color_block clamps to image bounds
fn test_average_color_block_clamps_to_bounds() {
	// 2x2 image, request a 4x4 block starting at (0,0) - should clamp to image size
	img := [
		Color{100, 100, 100},
		Color{100, 100, 100},
		Color{100, 100, 100},
		Color{100, 100, 100},
	]
	result := average_color_block(img, 0, 0, 4, 4, 2, 2)
	assert result.r == 100
	assert result.g == 100
	assert result.b == 100
}

// test_average_color_block_zero_size Test average_color_block returns black for zero-size block
fn test_average_color_block_zero_size() {
	img := [Color{255, 255, 255}]
	result := average_color_block(img, 0, 0, 0, 0, 1, 1)
	assert result.r == 0
	assert result.g == 0
	assert result.b == 0
}

// test_average_color_block_single_row Test average_color_block with a single row
fn test_average_color_block_single_row() {
	img := [
		Color{10, 20, 30},
		Color{30, 40, 50},
		Color{50, 60, 70},
	]
	result := average_color_block(img, 0, 0, 3, 1, 3, 1)
	assert result.r == 30 // (10+30+50)/3
	assert result.g == 40 // (20+40+60)/3
	assert result.b == 50 // (30+50+70)/3
}

// test_average_color_block_single_column Test average_color_block with a single column
fn test_average_color_block_single_column() {
	// 1x3 image
	img := [
		Color{10, 20, 30},
		Color{30, 40, 50},
		Color{50, 60, 70},
	]
	result := average_color_block(img, 0, 0, 1, 3, 1, 3)
	assert result.r == 30
	assert result.g == 40
	assert result.b == 50
}

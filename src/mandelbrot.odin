// mandelbrot.odin
//
// Generates Mandelbrot set visualizations in ASCII or gnuplot text format.
// Odin port of mandelbrot.c (cross-language comparison project).
// Parses command-line arguments in the format key=value.
//
// Build:
//   odin build mandelbrot.odin -file -o:speed
//
// Usage:
//   ./mandelbrot
//   ./mandelbrot width=120 ll_x=-0.75 ll_y=0.1 ur_x=-0.74 ur_y=0.11
//   ./mandelbrot png=1 width=800 height=600 > mandelbrot.dat

package mandelbrot

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

Config :: struct {
	width:    int,
	height:   int,
	png:      bool,
	ll_x:     f64,
	ll_y:     f64,
	ur_x:     f64,
	ur_y:     f64,
	max_iter: int,
}

// Maps an iteration count to an ASCII character.
cnt2char :: proc(value: int, max_iter: int) -> u8 {
	symbols := "MW2a_. "
	ns := len(symbols)
	idx := int(f64(value) / f64(max_iter) * f64(ns - 1))
	return symbols[idx]
}

// Calculates the escape time for a point in the complex plane.
escape_time :: proc(cr, ci: f64, max_iter: int) -> int {
	zr, zi: f64 = 0.0, 0.0
	iter := 0
	for ; iter < max_iter; iter += 1 {
		zr2 := zr * zr
		zi2 := zi * zi
		if zr2 + zi2 > 4.0 {
			break
		}
		tmp := zr2 - zi2 + cr
		zi = 2.0 * zr * zi + ci
		zr = tmp
	}
	return max_iter - iter
}

// Renders the Mandelbrot set as ASCII art to stdout.
ascii_output :: proc(config: ^Config) {
	fwidth := config.ur_x - config.ll_x
	fheight := config.ur_y - config.ll_y

	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)

	for y := 0; y < config.height; y += 1 {
		strings.builder_reset(&sb)
		for x := 0; x < config.width; x += 1 {
			real := config.ll_x + f64(x) * fwidth / f64(config.width)
			imag := config.ur_y - f64(y) * fheight / f64(config.height)
			iter := escape_time(real, imag, config.max_iter)
			strings.write_byte(&sb, cnt2char(iter, config.max_iter))
		}
		strings.write_byte(&sb, '\n')
		fmt.print(strings.to_string(sb))
	}
}

// Generates text output suitable for gnuplot to stdout.
gptext_output :: proc(config: ^Config) {
	fwidth := config.ur_x - config.ll_x
	fheight := config.ur_y - config.ll_y

	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)

	for y := config.height-1; y >= 0; y -= 1 {
		strings.builder_reset(&sb)
		for x := 0; x < config.width; x += 1 {
			real := config.ll_x + f64(x) * fwidth / f64(config.width)
			imag := config.ur_y - f64(y) * fheight / f64(config.height)
			iter := escape_time(real, imag, config.max_iter)

			if x > 0 {
				strings.write_string(&sb, ", ")
			}
			strings.write_int(&sb, iter)
		}
		strings.write_byte(&sb, '\n')
		fmt.print(strings.to_string(sb))
	}
}

// Parses a single "key=value" command-line argument.
parse_arg :: proc(arg: string, config: ^Config) {
	idx := strings.index_byte(arg, '=')
	if idx == -1 {
		fmt.eprintf("Warning: Ignoring invalid argument '%s'\n", arg)
		return
	}
	key := arg[:idx]
	value := arg[idx + 1:]

	switch key {
	case "width":
		config.width, _ = strconv.parse_int(value)
	case "height":
		config.height, _ = strconv.parse_int(value)
	case "png":
		n, _ := strconv.parse_int(value)
		config.png = n != 0
	case "ll_x":
		config.ll_x, _ = strconv.parse_f64(value)
	case "ll_y":
		config.ll_y, _ = strconv.parse_f64(value)
	case "ur_x":
		config.ur_x, _ = strconv.parse_f64(value)
	case "ur_y":
		config.ur_y, _ = strconv.parse_f64(value)
	case "max_iter":
		config.max_iter, _ = strconv.parse_int(value)
	case:
		fmt.eprintf("Warning: Unknown parameter '%s'\n", key)
	}
}

main :: proc() {
	config := Config {
		width    = 100,
		height   = 75,
		png      = false,
		ll_x     = -1.2,
		ll_y     = 0.20,
		ur_x     = -1.0,
		ur_y     = 0.35,
		max_iter = 255,
	}

	for arg in os.args[1:] {
		parse_arg(arg, &config)
	}

	if config.png {
		gptext_output(&config)
	} else {
		ascii_output(&config)
	}
}

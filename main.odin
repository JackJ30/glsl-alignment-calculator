#+feature dynamic-literals
package main

import "core:flags"
import "core:strconv"
import "core:strings"
import "core:fmt"
import os "core:os/os2"

version: enum {
	std140,
	std430,
} = .std140

main :: proc() {

	// parse options
	opts: struct {
		std140: bool `usage:"Use std140 layout (default)"`,
		std430: bool `usage:"Use std430 layout"`, 
	}
	flags.parse_or_exit(&opts, os.args, .Unix)
	if opts.std430 do version = .std430

	// read from stdin
	input, err := os.read_entire_file_from_file(os.stdin, context.temp_allocator)
	if err != nil {
		panic("Failed to read input")
	}
	lines := strings.split(string(input), "\n", context.temp_allocator)

	Block_Type :: enum { Uniform, Structure, Storage }
	Parsed_Block :: struct {
		type: Block_Type,
		name: string,
		types: []Type,
		names: []string,
	}
	parsed_blocks: [dynamic]Parsed_Block

	// read lines
	type: Block_Type = .Uniform
	name: string = "Block"
	types: [dynamic]Type
	names: [dynamic]string
	for &line, i in lines {

		// check if we start a new block
		if strings.index(line, "#") != -1 {
			// end current block
			if len(types) > 0 {
				append(&parsed_blocks, Parsed_Block{ type = type, name = name, types = types[:], names = names[:] })
				if type == .Structure {
					type_map[name] = types[:]
				}
			}

			// start new block
			types = make([dynamic]Type, 0)
			names = make([dynamic]string, 0)
			if strings.index(line, "#struct") != -1 {
				type = .Structure
			} else if strings.index(line, "#uniform") != -1 {
				type = .Uniform
			} else if strings.index(line, "#storage") != -1 {
				type = .Storage
			} else {
				fmt.panicf("Bad new block directive at line: %v", i)
			}
			name = line[strings.index(line, " ") + 1:]

			continue
		}

		// discard after semicolon
		semicolon_idx := strings.index(line, ";")
		if semicolon_idx != -1 do line = line[:semicolon_idx]

		// get fields
		fields := strings.fields(line, context.temp_allocator)
		if len(fields) == 0 do continue
		else if len(fields) != 2 do fmt.panicf("Wrong number of fields on line: %v", i)

		// parse first half
		type, ok := type_map[fields[0]]
		if !ok {
			fmt.panicf("Unknown type '%v' on line: %v", fields[0], i)
		}

		// parse second half
		second_half := fields[1]

		// check if there is an array in the name
		array_start := strings.index(second_half, "[")
		array_end := strings.index(second_half, "]")
		if array_start != -1 && array_end != -1 {
			if array_start + 1 >= array_end {
				fmt.panicf("Messed up array on line: %v", i)
			}
				
			// parse array size
			array_size, ok := strconv.parse_int(second_half[array_start + 1 : array_end])
			if !ok {
				fmt.panicf("Invalid array size on line: %v", i)
			}

			// make array based on type
			switch t in type {
			case Scalar:
				type = Array { type = t, size = array_size }
			case Vector:
				type = Array { type = t, size = array_size }
			case Matrix:
				type = Array { type = t, size = array_size }
			case Structure:
				type = Array { type = t, size = array_size }
			case Array:
				fmt.panicf("Cannot have an array of arrays on line: %v", i)
			}
		} else if array_start != -1 || array_end != -1 {
			fmt.panicf("Unbalanced array on line: %v", i)
		}

		append(&types, type)
		append(&names, line)
	}
	// end current block
	if len(types) > 0 {
		append(&parsed_blocks, Parsed_Block{ type = type, name = name, types = types[:], names = names[:] })
		if type == .Structure {
			type_map[name] = types[:]
		}
	}

	for &parsed in parsed_blocks {
		calc := calculate_block(parsed.types)

		fmt.printfln("%v %v: (size %v)", parsed.type, parsed.name, calc.total_size)

		prev_end := 0
		for _, i in parsed.types {
			if calc.offsets[i] > prev_end {
				fmt.printfln("%v-%v: PADDING", prev_end, calc.offsets[i] - 1)
			}
			prev_end = calc.offsets[i] + calc.sizes[i]
			fmt.printfln("%v-%v: %v", calc.offsets[i], calc.offsets[i] + calc.sizes[i] - 1, parsed.names[i])
		}

		fmt.println("")
	}
}

type_map := map[string]Type{
	"bool"    = .single,
	"float"   = .single,
	"int"     = .single,
	"uint"    = .single,
	"double"  = .double,

	"vec2"    = Vector{ type = .single, count = .two },
	"vec3"    = Vector{ type = .single, count = .three },
	"vec4"    = Vector{ type = .single, count = .four },

	"bvec2"   = Vector{ type = .single, count = .two },
	"bvec3"   = Vector{ type = .single, count = .three },
	"bvec4"   = Vector{ type = .single, count = .four },

	"ivec2"   = Vector{ type = .single, count = .two },
	"ivec3"   = Vector{ type = .single, count = .three },
	"ivec4"   = Vector{ type = .single, count = .four },

	"uvec2"   = Vector{ type = .single, count = .two },
	"uvec3"   = Vector{ type = .single, count = .three },
	"uvec4"   = Vector{ type = .single, count = .four },

	"dvec2"   = Vector{ type = .double, count = .two },
	"dvec3"   = Vector{ type = .double, count = .three },
	"dvec4"   = Vector{ type = .double, count = .four },

	"mat2"    = Matrix{ type = .single, major = .two,   minor = .two },
	"mat3"    = Matrix{ type = .single, major = .three, minor = .three },
	"mat4"    = Matrix{ type = .single, major = .four,  minor = .four },

	"mat2x2"  = Matrix{ type = .single, major = .two,   minor = .two },
	"mat2x3"  = Matrix{ type = .single, major = .two,   minor = .three },
	"mat2x4"  = Matrix{ type = .single, major = .two,   minor = .four },

	"mat3x2"  = Matrix{ type = .single, major = .three, minor = .two },
	"mat3x3"  = Matrix{ type = .single, major = .three, minor = .three },
	"mat3x4"  = Matrix{ type = .single, major = .three, minor = .four },

	"mat4x2"  = Matrix{ type = .single, major = .four,  minor = .two },
	"mat4x3"  = Matrix{ type = .single, major = .four,  minor = .three },
	"mat4x4"  = Matrix{ type = .single, major = .four,  minor = .four },

	"dmat2"   = Matrix{ type = .double, major = .two,   minor = .two },
	"dmat3"   = Matrix{ type = .double, major = .three, minor = .three },
	"dmat4"   = Matrix{ type = .double, major = .four,  minor = .four },

	"dmat2x2" = Matrix{ type = .double, major = .two,   minor = .two },
	"dmat2x3" = Matrix{ type = .double, major = .two,   minor = .three },
	"dmat2x4" = Matrix{ type = .double, major = .two,   minor = .four },

	"dmat3x2" = Matrix{ type = .double, major = .three, minor = .two },
	"dmat3x3" = Matrix{ type = .double, major = .three, minor = .three },
	"dmat3x4" = Matrix{ type = .double, major = .three, minor = .four },

	"dmat4x2" = Matrix{ type = .double, major = .four,  minor = .two },
	"dmat4x3" = Matrix{ type = .double, major = .four,  minor = .three },
	"dmat4x4" = Matrix{ type = .double, major = .four,  minor = .four },
}

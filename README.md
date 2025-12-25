# GLSL Std140 and Std430 Layout Calculator
Reference: https://registry.khronos.org/OpenGL/specs/gl/glspec46.core.pdf pages 146-147

## Usage
Feed it input through stdin. By default the program calculator `std140` layout, the `--std430` flag switches it to `std430`. \
Example input (similar to glsl):
```
vec3 position
float rotation
vec2 scale
vec2 padding
float texu
float texv
float texw
float texh
vec4 color
```
or with explicit blocks
```
#struct light
vec4 position
float strength
float parameters[3]

#uniform main
mat4 view
light lights[32]
```

## Example Output
```
Uniform Block: (size 64)
0-11: vec3 position
12-15: float rotation
16-23: vec2 scale
24-31: vec2 padding
32-35: float texu
36-39: float texv
40-43: float texw
44-47: float texh
48-63: vec4 color
```
```
Structure light: (size 80)
0-15: vec4 position
16-19: float strength
20-31: PADDING
32-79: float parameters[3]

Uniform main: (size 2624)
0-63: mat4 view
64-2623: light lights[32]
```
## TODO
- [x] Input
- [x] Array of structs
- [x] Parse structures
- [x] flag for std140 vs 430
- [ ] More helpful array output
- [ ] parse "buffers" (with unsized array)

- [ ] web version
- [ ] blog post


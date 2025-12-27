# GLSL Std140 and Std430 Layout Calculator
Reference: https://registry.khronos.org/OpenGL/specs/gl/glspec46.core.pdf pages 146-147

## Usage
Feed it input through stdin. By default the program calculator `std140` layout, the `--std430` flag switches it to `std430`. \
Example input (similar to glsl):
```
vec3 position
float rotation
vec2 scale
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
Uniform Implicit: (size 64)
0-11: vec3 position
12-15: float rotation
16-23: vec2 scale
24-27: float texu
28-31: float texv
32-35: float texw
36-39: float texh
40-47: IMPLICIT PADDING
48-63: vec4 color
```
or
```
Struct light: (size 80)
0-15: vec4 position
16-19: float strength
20-31: IMPLICIT PADDING
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
- [x] big refactor
- [ ] display errors and struct end padding
- [ ] switch to blocks defined by double newline
- [ ] Output improvements -> color, nested output, array elements
- [ ] "storage" block with allowed unsized array at end

- [x] web version
- [x] improve web version (automatically run)
- [ ] add web version to my site
- [ ] blog post


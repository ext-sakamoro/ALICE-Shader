# ALICE-Shader

Unified shader library for the ALICE Eco-System. GLSL + WGSL sources for sky, terrain, PBR, SDF, and VFX.

## Usage

```rust
// GLSL
let sky_glsl = alice_shader::glsl::SKY;

// WGSL
let sky_wgsl = alice_shader::wgsl::SKY;

// Registry lookup
let reg = alice_shader::registry::ShaderRegistry::builtin();
let src = reg.get("sky", alice_shader::registry::ShaderLang::Wgsl).unwrap();
```

## Shaders

| Name | GLSL | WGSL | Origin |
|------|------|------|--------|
| noise | hash, vnoise, fbm | — | alice-universe.glsl |
| terrain | biome system (snow/desert/rock/grass) | — | alice-universe.glsl |
| sdf_primitives | sphere, box, capsule | — | alice-universe.glsl |
| vfx | domain warping, fractal folding | — | alice-universe.glsl |
| pbr | Cook-Torrance, materials | — | alice-universe.glsl |
| sky | Rayleigh/Mie, clouds, stars | sky.wgsl | alice-universe.glsl |
| gbuffer_vertex | — | MVP transform | ALICE-GameEngine |
| gbuffer_fragment | — | PBR material output | ALICE-GameEngine |
| sdf_raymarch | — | sphere tracing | ALICE-GameEngine |
| deferred_lighting | — | 16-light deferred | ALICE-GameEngine |

## References

- [ALICE-SDF-Experiment](https://alice-sdf-experiment.pages.dev/) — alice-universe.glsl source
- [ALICE-GameEngine](https://github.com/ext-sakamoro/ALICE-GameEngine) — WGSL shaders
- [ALICE-SDF](https://github.com/ext-sakamoro/ALICE-SDF) — SDF eval shaders

## License

MIT OR Commercial

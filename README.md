# ALICE-Shader

> **Status: frozen (2026-09-14).** No ALICE-* crate consumes this library.
> The canonical source of SDF primitives is `alice-sdf`, whose transpiler
> generates GLSL / WGSL / HLSL from one `SdfNode` definition; the hand-written
> `sdf_primitives.glsl` / `sdf_primitives.wgsl` here are legacy copies whose
> parity with each other and with `alice-sdf` is **not** verified
> (ALICE-SDF-LAWS §SDF ↔ Physics 同期の法 §5 priority 3, no oracle). If this
> crate is revived, replace the hand-written primitives with transpiler output
> instead of adding a parity oracle.

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
| noise | hash, vnoise, fbm | hash, vnoise, fbm | alice-universe.glsl |
| terrain | biome system (dot-product sector weights) | — | alice-universe.glsl |
| sdf_primitives | sphere, box, torus, cylinder, gyroid, smin | sphere, box, torus, cylinder, gyroid, smin | alice-universe.glsl |
| vfx | domain warping, fractal folding | — | alice-universe.glsl |
| pbr | 18 materials (int-indexed branching) | — | alice-universe.glsl |
| sky | Rayleigh/Mie, ozone, moon, stars, aurora, clouds | Rayleigh/Mie, ozone, moon, stars, milky way, clouds | alice-universe.glsl |
| gbuffer_vertex | — | MVP transform | ALICE-GameEngine |
| gbuffer_fragment | — | PBR material output | ALICE-GameEngine |
| sdf_raymarch | — | sphere tracing, gradient normals, soft shadow, AO | ALICE-GameEngine |
| deferred_lighting | — | Cook-Torrance BRDF, 16 lights | ALICE-GameEngine |

## References

- [ALICE-SDF-Experiment](https://alice-sdf-experiment.pages.dev/) — alice-universe.glsl source
- [ALICE-GameEngine](https://github.com/ext-sakamoro/ALICE-GameEngine) — WGSL shaders
- [ALICE-SDF](https://github.com/ext-sakamoro/ALICE-SDF) — SDF eval shaders

## License

MIT OR Commercial

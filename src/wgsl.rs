//! WGSL shader sources (embedded at compile time).

/// Noise functions (hash, vnoise, fbm).
pub const NOISE: &str = include_str!("wgsl/noise.wgsl");

/// `GBuffer` vertex shader (MVP transform).
pub const GBUFFER_VERTEX: &str = include_str!("wgsl/gbuffer_vertex.wgsl");

/// `GBuffer` fragment shader (PBR material output).
pub const GBUFFER_FRAGMENT: &str = include_str!("wgsl/gbuffer_fragment.wgsl");

/// SDF primitives (sphere, box, cylinder, torus, etc.).
pub const SDF_PRIMITIVES: &str = include_str!("wgsl/sdf_primitives.wgsl");

/// SDF raymarch fragment shader (sphere tracing, soft shadow, AO).
pub const SDF_RAYMARCH: &str = include_str!("wgsl/sdf_raymarch.wgsl");

/// Deferred lighting fragment shader (Cook-Torrance BRDF, 16 lights).
pub const DEFERRED_LIGHTING: &str = include_str!("wgsl/deferred_lighting.wgsl");

/// Physical sky fragment shader (Rayleigh/Mie, stars, moon, clouds).
pub const SKY: &str = include_str!("wgsl/sky.wgsl");

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn noise_has_hash() {
        assert!(NOISE.contains("hash"));
        assert!(NOISE.contains("vnoise"));
        assert!(NOISE.contains("fbm"));
    }

    #[test]
    fn gbuffer_vertex_has_entry() {
        assert!(GBUFFER_VERTEX.contains("@vertex"));
    }

    #[test]
    fn gbuffer_fragment_has_entry() {
        assert!(GBUFFER_FRAGMENT.contains("@fragment"));
    }

    #[test]
    fn sdf_primitives_has_shapes() {
        assert!(SDF_PRIMITIVES.contains("sd_sphere"));
        assert!(SDF_PRIMITIVES.contains("sd_box"));
        assert!(SDF_PRIMITIVES.contains("sd_torus"));
        assert!(SDF_PRIMITIVES.contains("sd_cylinder"));
        assert!(SDF_PRIMITIVES.contains("sd_gyroid"));
        assert!(SDF_PRIMITIVES.contains("smin"));
    }

    #[test]
    fn sdf_raymarch_has_features() {
        assert!(SDF_RAYMARCH.contains("sdf_sphere"));
        assert!(SDF_RAYMARCH.contains("calc_normal"));
        assert!(SDF_RAYMARCH.contains("soft_shadow"));
        assert!(SDF_RAYMARCH.contains("calc_ao"));
    }

    #[test]
    fn deferred_lighting_has_brdf() {
        assert!(DEFERRED_LIGHTING.contains("Light"));
        assert!(DEFERRED_LIGHTING.contains("distribution_ggx"));
        assert!(DEFERRED_LIGHTING.contains("fresnel_schlick"));
        assert!(DEFERRED_LIGHTING.contains("geometry_smith"));
    }

    #[test]
    fn sky_has_features() {
        assert!(SKY.contains("Rayleigh") || SKY.contains("rayleigh") || SKY.contains("bR"));
        assert!(SKY.contains("moon") || SKY.contains("Moon") || SKY.contains("moon_dir"));
        assert!(SKY.contains("star") || SKY.contains("Star") || SKY.contains("starB"));
        assert!(SKY.contains("Cumulus") || SKY.contains("cloud") || SKY.contains("cUV"));
    }

    // ── WGSL構文検証 ──

    #[test]
    fn all_wgsl_shaders_have_fn() {
        for (name, src) in [
            ("noise", NOISE),
            ("gbuffer_vertex", GBUFFER_VERTEX),
            ("gbuffer_fragment", GBUFFER_FRAGMENT),
            ("sdf_primitives", SDF_PRIMITIVES),
            ("sdf_raymarch", SDF_RAYMARCH),
            ("deferred_lighting", DEFERRED_LIGHTING),
            ("sky", SKY),
        ] {
            assert!(src.contains("fn "), "WGSL shader '{name}' missing 'fn' keyword");
        }
    }

    #[test]
    fn entry_point_shaders_have_annotations() {
        for (name, src) in [
            ("gbuffer_vertex", GBUFFER_VERTEX),
            ("gbuffer_fragment", GBUFFER_FRAGMENT),
            ("sdf_raymarch", SDF_RAYMARCH),
            ("deferred_lighting", DEFERRED_LIGHTING),
            ("sky", SKY),
        ] {
            assert!(
                src.contains("@vertex") || src.contains("@fragment") || src.contains("@compute"),
                "WGSL entry-point shader '{name}' missing stage annotation"
            );
        }
    }
}

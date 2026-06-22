//! GLSL shader sources (embedded at compile time).

/// Noise functions (hash, vnoise, fbm).
pub const NOISE: &str = include_str!("glsl/noise.glsl");

/// Biome terrain system (dot-product sector weights).
pub const TERRAIN: &str = include_str!("glsl/terrain.glsl");

/// SDF primitives (sphere, box, capsule, etc.).
pub const SDF_PRIMITIVES: &str = include_str!("glsl/sdf_primitives.glsl");

/// VFX foundation (domain warping, fractal folding).
pub const VFX: &str = include_str!("glsl/vfx.glsl");

/// PBR materials (18 materials, int-indexed branching).
pub const PBR: &str = include_str!("glsl/pbr.glsl");

/// Physical sky (Rayleigh/Mie scattering, clouds, stars).
pub const SKY: &str = include_str!("glsl/sky.glsl");

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn noise_has_functions() {
        assert!(NOISE.contains("hash("));
        assert!(NOISE.contains("vnoise("));
        assert!(NOISE.contains("fbm("));
        assert!(NOISE.contains("vnoise3("));
        assert!(NOISE.contains("fbm3("));
    }

    #[test]
    fn terrain_has_biome_system() {
        assert!(TERRAIN.contains("biomeWeights"));
        assert!(TERRAIN.contains("terrainHeight"));
        assert!(TERRAIN.contains("voronoiErosion"));
        assert!(
            !TERRAIN.contains("atan("),
            "terrain should use dot-product, not atan"
        );
    }

    #[test]
    fn sdf_primitives_has_shapes() {
        assert!(SDF_PRIMITIVES.contains("sdBox("));
        assert!(SDF_PRIMITIVES.contains("sdSphere("));
        assert!(SDF_PRIMITIVES.contains("sdTorus("));
        assert!(SDF_PRIMITIVES.contains("sdCylinder("));
        assert!(SDF_PRIMITIVES.contains("sdGyroid("));
        assert!(SDF_PRIMITIVES.contains("smin("));
    }

    #[test]
    fn vfx_has_functions() {
        assert!(VFX.contains("blackbody("));
        assert!(VFX.contains("spectralToRGB("));
        assert!(VFX.contains("microNormal("));
        assert!(VFX.contains("dWarp("));
        assert!(VFX.contains("dbmDischarge("));
    }

    #[test]
    fn pbr_uses_int_branching() {
        assert!(PBR.contains("int mid=int(id+0.5)"));
        assert!(PBR.contains("if(mid==0)"));
    }

    #[test]
    fn sky_has_rayleigh() {
        assert!(SKY.contains("Rayleigh") || SKY.contains("rayleigh"));
        assert!(SKY.contains("skyColor("));
    }

    #[test]
    fn sky_has_features() {
        assert!(SKY.contains("moonDir") || SKY.contains("moonDot"));
        assert!(SKY.contains("starB") || SKY.contains("starC"));
        assert!(SKY.contains("Cumulus") || SKY.contains("cUV"));
        assert!(SKY.contains("aurora") || SKY.contains("Aurora"));
    }

    // ── GLSL/WGSL パリティ検証 ──

    #[test]
    fn parity_noise_functions_exist_in_both() {
        let wgsl = crate::wgsl::NOISE;
        assert!(wgsl.contains("hash"), "WGSL noise missing hash");
        assert!(wgsl.contains("vnoise"), "WGSL noise missing vnoise");
        assert!(wgsl.contains("fbm"), "WGSL noise missing fbm");
    }

    #[test]
    fn parity_sdf_primitives_in_both() {
        let wgsl = crate::wgsl::SDF_PRIMITIVES;
        for name in ["sphere", "box", "torus", "cylinder", "gyroid", "smin"] {
            assert!(wgsl.contains(name), "WGSL sdf_primitives missing {name}");
        }
    }

    #[test]
    fn parity_sky_in_both() {
        let wgsl = crate::wgsl::SKY;
        assert!(wgsl.contains("Rayleigh") || wgsl.contains("rayleigh") || wgsl.contains("bR"));
    }
}

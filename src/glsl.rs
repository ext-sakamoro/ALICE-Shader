//! GLSL shader sources (embedded at compile time).

/// Noise functions (hash, vnoise, fbm).
pub const NOISE: &str = include_str!("glsl/noise.glsl");

/// Biome terrain system (snow, desert, rock, grass).
pub const TERRAIN: &str = include_str!("glsl/terrain.glsl");

/// SDF primitives (sphere, box, capsule, etc.).
pub const SDF_PRIMITIVES: &str = include_str!("glsl/sdf_primitives.glsl");

/// VFX foundation (domain warping, fractal folding).
pub const VFX: &str = include_str!("glsl/vfx.glsl");

/// PBR materials (Cook-Torrance, roughness, metallic).
pub const PBR: &str = include_str!("glsl/pbr.glsl");

/// Physical sky (Rayleigh/Mie scattering, clouds, stars).
pub const SKY: &str = include_str!("glsl/sky.glsl");

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn noise_not_empty() {
        assert!(!NOISE.is_empty());
        assert!(NOISE.contains("hash"));
    }

    #[test]
    fn terrain_has_biome() {
        assert!(TERRAIN.contains("biome") || TERRAIN.contains("Biome"));
    }

    #[test]
    fn sky_has_rayleigh() {
        assert!(SKY.contains("Rayleigh") || SKY.contains("rayleigh"));
    }

    #[test]
    fn pbr_not_empty() {
        assert!(!PBR.is_empty());
    }

    #[test]
    fn sdf_primitives_not_empty() {
        assert!(!SDF_PRIMITIVES.is_empty());
    }

    #[test]
    fn vfx_not_empty() {
        assert!(!VFX.is_empty());
    }
}

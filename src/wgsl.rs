//! WGSL shader sources (embedded at compile time).

/// `GBuffer` vertex shader (MVP transform).
pub const GBUFFER_VERTEX: &str = include_str!("wgsl/gbuffer_vertex.wgsl");

/// `GBuffer` fragment shader (PBR material output).
pub const GBUFFER_FRAGMENT: &str = include_str!("wgsl/gbuffer_fragment.wgsl");

/// SDF raymarch fragment shader (sphere tracing).
pub const SDF_RAYMARCH: &str = include_str!("wgsl/sdf_raymarch.wgsl");

/// Deferred lighting fragment shader (16 lights).
pub const DEFERRED_LIGHTING: &str = include_str!("wgsl/deferred_lighting.wgsl");

/// Physical sky fragment shader (Rayleigh/Mie).
pub const SKY: &str = include_str!("wgsl/sky.wgsl");

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn gbuffer_vertex_has_entry() {
        assert!(GBUFFER_VERTEX.contains("@vertex"));
    }

    #[test]
    fn gbuffer_fragment_has_entry() {
        assert!(GBUFFER_FRAGMENT.contains("@fragment"));
    }

    #[test]
    fn sdf_raymarch_has_sphere() {
        assert!(SDF_RAYMARCH.contains("sdf_sphere"));
    }

    #[test]
    fn deferred_lighting_has_lights() {
        assert!(DEFERRED_LIGHTING.contains("Light"));
    }

    #[test]
    fn sky_has_rayleigh() {
        assert!(SKY.contains("Rayleigh") || SKY.contains("rayleigh") || SKY.contains("bR"));
    }
}

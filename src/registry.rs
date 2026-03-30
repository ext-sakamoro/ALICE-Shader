//! Shader registry: look up shaders by name and target language.

/// Target shader language.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ShaderLang {
    Glsl,
    Wgsl,
}

/// A shader entry in the registry.
#[derive(Debug, Clone, Copy)]
pub struct ShaderEntry {
    pub name: &'static str,
    pub lang: ShaderLang,
    pub source: &'static str,
}

const GLSL_ENTRIES: &[(&str, &str)] = &[
    ("noise", crate::glsl::NOISE),
    ("terrain", crate::glsl::TERRAIN),
    ("sdf_primitives", crate::glsl::SDF_PRIMITIVES),
    ("vfx", crate::glsl::VFX),
    ("pbr", crate::glsl::PBR),
    ("sky", crate::glsl::SKY),
];

const WGSL_ENTRIES: &[(&str, &str)] = &[
    ("noise", crate::wgsl::NOISE),
    ("gbuffer_vertex", crate::wgsl::GBUFFER_VERTEX),
    ("gbuffer_fragment", crate::wgsl::GBUFFER_FRAGMENT),
    ("sdf_primitives", crate::wgsl::SDF_PRIMITIVES),
    ("sdf_raymarch", crate::wgsl::SDF_RAYMARCH),
    ("deferred_lighting", crate::wgsl::DEFERRED_LIGHTING),
    ("sky", crate::wgsl::SKY),
];

/// Registry of all available shaders.
pub struct ShaderRegistry;

impl ShaderRegistry {
    /// Creates a registry (zero-allocation, all lookups are static).
    #[must_use]
    pub fn builtin() -> Self {
        Self
    }

    /// Looks up a shader by name and language.
    #[must_use]
    pub fn get(&self, name: &str, lang: ShaderLang) -> Option<&'static str> {
        let entries = match lang {
            ShaderLang::Glsl => GLSL_ENTRIES,
            ShaderLang::Wgsl => WGSL_ENTRIES,
        };
        entries.iter().find(|(n, _)| *n == name).map(|(_, s)| *s)
    }

    /// Returns all shader names for a given language.
    #[must_use]
    pub fn names(&self, lang: ShaderLang) -> Vec<&'static str> {
        let entries = match lang {
            ShaderLang::Glsl => GLSL_ENTRIES,
            ShaderLang::Wgsl => WGSL_ENTRIES,
        };
        entries.iter().map(|(n, _)| *n).collect()
    }

    /// Iterates over all shader entries across both languages.
    pub fn iter(&self) -> impl Iterator<Item = ShaderEntry> {
        GLSL_ENTRIES
            .iter()
            .map(|(n, s)| ShaderEntry { name: n, lang: ShaderLang::Glsl, source: s })
            .chain(
                WGSL_ENTRIES
                    .iter()
                    .map(|(n, s)| ShaderEntry { name: n, lang: ShaderLang::Wgsl, source: s }),
            )
    }

    /// Total entries.
    #[must_use]
    pub fn count(&self) -> usize {
        GLSL_ENTRIES.len() + WGSL_ENTRIES.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builtin_has_entries() {
        let reg = ShaderRegistry::builtin();
        assert!(reg.count() >= 13);
    }

    #[test]
    fn lookup_sky_glsl() {
        let reg = ShaderRegistry::builtin();
        assert!(reg.get("sky", ShaderLang::Glsl).is_some());
    }

    #[test]
    fn lookup_sky_wgsl() {
        let reg = ShaderRegistry::builtin();
        assert!(reg.get("sky", ShaderLang::Wgsl).is_some());
    }

    #[test]
    fn lookup_noise_wgsl() {
        let reg = ShaderRegistry::builtin();
        assert!(reg.get("noise", ShaderLang::Wgsl).is_some());
    }

    #[test]
    fn lookup_sdf_primitives_wgsl() {
        let reg = ShaderRegistry::builtin();
        assert!(reg.get("sdf_primitives", ShaderLang::Wgsl).is_some());
    }

    #[test]
    fn lookup_missing() {
        let reg = ShaderRegistry::builtin();
        assert!(reg.get("nonexistent", ShaderLang::Glsl).is_none());
    }

    #[test]
    fn glsl_names() {
        let reg = ShaderRegistry::builtin();
        let names = reg.names(ShaderLang::Glsl);
        assert!(names.len() >= 6);
    }

    #[test]
    fn wgsl_names() {
        let reg = ShaderRegistry::builtin();
        let names = reg.names(ShaderLang::Wgsl);
        assert!(names.len() >= 7);
    }

    #[test]
    fn iter_yields_all() {
        let reg = ShaderRegistry::builtin();
        let entries: Vec<_> = reg.iter().collect();
        assert_eq!(entries.len(), reg.count());
        assert!(entries.iter().all(|e| !e.source.is_empty()));
    }

    #[test]
    fn iter_entry_fields() {
        let reg = ShaderRegistry::builtin();
        let sky = reg.iter().find(|e| e.name == "sky" && e.lang == ShaderLang::Glsl);
        assert!(sky.is_some());
        assert!(sky.unwrap().source.contains("Rayleigh") || sky.unwrap().source.contains("rayleigh"));
    }
}

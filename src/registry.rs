//! Shader registry: look up shaders by name and target language.

use std::collections::HashMap;

/// Target shader language.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ShaderLang {
    Glsl,
    Wgsl,
}

/// A shader entry in the registry.
#[derive(Debug, Clone)]
pub struct ShaderEntry {
    pub name: String,
    pub lang: ShaderLang,
    pub source: &'static str,
}

/// Registry of all available shaders.
pub struct ShaderRegistry {
    entries: HashMap<(String, ShaderLang), &'static str>,
}

impl ShaderRegistry {
    /// Creates a registry pre-loaded with all built-in shaders.
    #[must_use]
    pub fn builtin() -> Self {
        let mut entries = HashMap::new();
        let add = |m: &mut HashMap<(String, ShaderLang), &'static str>,
                   name: &str,
                   lang: ShaderLang,
                   src: &'static str| {
            m.insert((name.to_string(), lang), src);
        };

        // GLSL
        add(&mut entries, "noise", ShaderLang::Glsl, crate::glsl::NOISE);
        add(
            &mut entries,
            "terrain",
            ShaderLang::Glsl,
            crate::glsl::TERRAIN,
        );
        add(
            &mut entries,
            "sdf_primitives",
            ShaderLang::Glsl,
            crate::glsl::SDF_PRIMITIVES,
        );
        add(&mut entries, "vfx", ShaderLang::Glsl, crate::glsl::VFX);
        add(&mut entries, "pbr", ShaderLang::Glsl, crate::glsl::PBR);
        add(&mut entries, "sky", ShaderLang::Glsl, crate::glsl::SKY);

        // WGSL
        add(
            &mut entries,
            "gbuffer_vertex",
            ShaderLang::Wgsl,
            crate::wgsl::GBUFFER_VERTEX,
        );
        add(
            &mut entries,
            "gbuffer_fragment",
            ShaderLang::Wgsl,
            crate::wgsl::GBUFFER_FRAGMENT,
        );
        add(
            &mut entries,
            "sdf_raymarch",
            ShaderLang::Wgsl,
            crate::wgsl::SDF_RAYMARCH,
        );
        add(
            &mut entries,
            "deferred_lighting",
            ShaderLang::Wgsl,
            crate::wgsl::DEFERRED_LIGHTING,
        );
        add(&mut entries, "sky", ShaderLang::Wgsl, crate::wgsl::SKY);

        Self { entries }
    }

    /// Looks up a shader by name and language.
    #[must_use]
    pub fn get(&self, name: &str, lang: ShaderLang) -> Option<&'static str> {
        self.entries.get(&(name.to_string(), lang)).copied()
    }

    /// Returns all shader names for a given language.
    #[must_use]
    pub fn names(&self, lang: ShaderLang) -> Vec<&str> {
        self.entries
            .keys()
            .filter(|(_, l)| *l == lang)
            .map(|(n, _)| n.as_str())
            .collect()
    }

    /// Total entries.
    #[must_use]
    pub fn count(&self) -> usize {
        self.entries.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builtin_has_entries() {
        let reg = ShaderRegistry::builtin();
        assert!(reg.count() >= 11);
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
        assert!(names.len() >= 5);
    }
}

#![warn(clippy::all, clippy::pedantic)]

//! # ALICE-Shader
//!
//! Unified shader library for the ALICE Eco-System.
//! Provides GLSL and WGSL sources for sky, terrain, PBR, SDF, and VFX.
//!
//! ```rust
//! let sky_glsl = alice_shader::glsl::SKY;
//! let sky_wgsl = alice_shader::wgsl::SKY;
//! ```

pub mod glsl;
pub mod registry;
pub mod wgsl;

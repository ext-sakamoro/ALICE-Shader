struct FragmentInput {
    @location(0) world_normal: vec3<f32>,
    @location(1) world_position: vec3<f32>,
    @location(2) uv: vec2<f32>,
};

struct GBufferOutput {
    @location(0) albedo: vec4<f32>,
    @location(1) normal: vec4<f32>,
    @location(2) emission: vec4<f32>,
    @location(3) material: vec4<f32>,
};

struct Material {
    albedo: vec4<f32>,
    metallic: f32,
    roughness: f32,
    emission_strength: f32,
    _pad: f32,
};

@group(1) @binding(0) var<uniform> material: Material;

@fragment
fn fs_main(in: FragmentInput) -> GBufferOutput {
    var out: GBufferOutput;
    out.albedo = material.albedo;
    out.normal = vec4<f32>(normalize(in.world_normal) * 0.5 + 0.5, 1.0);
    out.emission = vec4<f32>(material.albedo.rgb * material.emission_strength, 1.0);
    out.material = vec4<f32>(material.metallic, material.roughness, 1.0, 0.0);
    return out;
}

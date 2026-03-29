@group(0) @binding(0) var t_albedo: texture_2d<f32>;
@group(0) @binding(1) var t_normal: texture_2d<f32>;
@group(0) @binding(2) var t_material: texture_2d<f32>;
@group(0) @binding(3) var s_linear: sampler;

struct Light {
    position: vec3<f32>,
    _pad0: f32,
    color: vec3<f32>,
    intensity: f32,
};

struct LightUniforms {
    camera_pos: vec3<f32>,
    light_count: u32,
    lights: array<Light, 16>,
};

@group(1) @binding(0) var<uniform> lu: LightUniforms;

@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let albedo = textureSample(t_albedo, s_linear, uv).rgb;
    let normal = textureSample(t_normal, s_linear, uv).rgb * 2.0 - 1.0;
    let material = textureSample(t_material, s_linear, uv);
    let roughness = material.g;

    var color = albedo * 0.03; // ambient
    for (var i: u32 = 0u; i < lu.light_count; i++) {
        let l = lu.lights[i];
        let light_dir = normalize(l.position - vec3<f32>(uv.x, uv.y, 0.0));
        let diff = max(dot(normal, light_dir), 0.0);
        color += albedo * l.color * diff * l.intensity;
    }
    return vec4<f32>(color, 1.0);
}

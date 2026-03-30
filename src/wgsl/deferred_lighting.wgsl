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

// GGX Normal Distribution Function
fn distribution_ggx(n_dot_h: f32, a2: f32) -> f32 {
    let denom = n_dot_h * n_dot_h * (a2 - 1.0) + 1.0;
    return a2 / (3.14159265 * denom * denom + 1e-7);
}

// Schlick Fresnel approximation
fn fresnel_schlick(cos_theta: f32, f0: vec3<f32>) -> vec3<f32> {
    let t = 1.0 - cos_theta;
    let t2 = t * t;
    return f0 + (1.0 - f0) * (t2 * t2 * t);
}

// Smith-GGX Geometry function (combined G1 for view and light)
fn geometry_smith(n_dot_v: f32, n_dot_l: f32, a2: f32) -> f32 {
    let g1_v = n_dot_v / (n_dot_v * (1.0 - a2 * 0.5) + a2 * 0.5 + 1e-7);
    let g1_l = n_dot_l / (n_dot_l * (1.0 - a2 * 0.5) + a2 * 0.5 + 1e-7);
    return g1_v * g1_l;
}

@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let albedo = textureSample(t_albedo, s_linear, uv).rgb;
    let normal = normalize(textureSample(t_normal, s_linear, uv).rgb * 2.0 - 1.0);
    let material = textureSample(t_material, s_linear, uv);
    let metallic = material.r;
    let roughness = max(material.g, 0.04);
    let a2 = roughness * roughness;

    let world_pos = vec3<f32>(uv.x, uv.y, 0.0);
    let view_dir = normalize(lu.camera_pos - world_pos);
    let n_dot_v = max(dot(normal, view_dir), 0.0);

    let f0 = mix(vec3<f32>(0.04), albedo, metallic);

    var color = albedo * 0.03;
    for (var i: u32 = 0u; i < lu.light_count; i++) {
        let l = lu.lights[i];
        let light_dir = normalize(l.position - world_pos);
        let half_vec = normalize(view_dir + light_dir);

        let n_dot_l = max(dot(normal, light_dir), 0.0);
        let n_dot_h = max(dot(normal, half_vec), 0.0);
        let v_dot_h = max(dot(view_dir, half_vec), 0.0);

        let d = distribution_ggx(n_dot_h, a2);
        let f = fresnel_schlick(v_dot_h, f0);
        let g = geometry_smith(n_dot_v, n_dot_l, a2);

        let specular = (d * g) * f / (4.0 * n_dot_v * n_dot_l + 1e-7);
        let k_d = (1.0 - f) * (1.0 - metallic);
        let diffuse = k_d * albedo / 3.14159265;

        color += (diffuse + specular) * l.color * l.intensity * n_dot_l;
    }
    return vec4<f32>(color, 1.0);
}

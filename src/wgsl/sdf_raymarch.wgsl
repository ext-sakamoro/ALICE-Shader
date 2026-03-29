struct RaymarchUniforms {
    camera_pos: vec3<f32>,
    _pad0: f32,
    camera_dir: vec3<f32>,
    _pad1: f32,
    resolution: vec2<f32>,
    time: f32,
    _pad2: f32,
};

@group(0) @binding(0) var<uniform> u: RaymarchUniforms;

fn sdf_sphere(p: vec3<f32>, r: f32) -> f32 {
    return length(p) - r;
}

fn sdf_box(p: vec3<f32>, b: vec3<f32>) -> f32 {
    let q = abs(p) - b;
    return length(max(q, vec3<f32>(0.0))) + min(max(q.x, max(q.y, q.z)), 0.0);
}

@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    let uv = (frag_coord.xy / u.resolution) * 2.0 - 1.0;
    let rd = normalize(vec3<f32>(uv.x, uv.y, -1.0));
    var t: f32 = 0.0;
    for (var i: i32 = 0; i < 64; i++) {
        let p = u.camera_pos + rd * t;
        let d = sdf_sphere(p, 1.0);
        if d < 0.001 {
            let n = normalize(p);
            let light = max(dot(n, normalize(vec3<f32>(1.0, 1.0, 1.0))), 0.1);
            return vec4<f32>(vec3<f32>(light), 1.0);
        }
        t += d;
        if t > 100.0 { break; }
    }
    return vec4<f32>(0.05, 0.05, 0.1, 1.0);
}

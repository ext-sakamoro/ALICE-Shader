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

fn sdf_smin(a: f32, b: f32, k: f32) -> f32 {
    let h = max(k - abs(a - b), 0.0);
    return min(a, b) - h * h * 0.25 / k;
}

fn scene(p: vec3<f32>) -> f32 {
    let s = sdf_sphere(p, 1.0);
    let b = sdf_box(p - vec3<f32>(2.0, 0.0, 0.0), vec3<f32>(0.7));
    let floor_d = p.y + 1.0;
    return min(sdf_smin(s, b, 0.5), floor_d);
}

fn calc_normal(p: vec3<f32>) -> vec3<f32> {
    let e = vec2<f32>(0.001, 0.0);
    return normalize(vec3<f32>(
        scene(p + e.xyy) - scene(p - e.xyy),
        scene(p + e.yxy) - scene(p - e.yxy),
        scene(p + e.yyx) - scene(p - e.yyx)
    ));
}

fn soft_shadow(ro: vec3<f32>, rd: vec3<f32>, t_min: f32, t_max: f32, k: f32) -> f32 {
    var res = 1.0;
    var t = t_min;
    for (var i: i32 = 0; i < 32; i++) {
        let d = scene(ro + rd * t);
        if d < 0.001 { return 0.0; }
        res = min(res, k * d / t);
        t += clamp(d, 0.02, 0.5);
        if t > t_max { break; }
    }
    return clamp(res, 0.0, 1.0);
}

fn calc_ao(p: vec3<f32>, n: vec3<f32>) -> f32 {
    var occ = 0.0;
    var scale = 1.0;
    for (var i: i32 = 1; i <= 5; i++) {
        let dist = 0.02 + 0.06 * f32(i);
        let d = scene(p + n * dist);
        occ += (dist - d) * scale;
        scale *= 0.65;
    }
    return clamp(1.0 - occ * 3.0, 0.0, 1.0);
}

@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    let uv = (frag_coord.xy / u.resolution) * 2.0 - 1.0;
    let rd = normalize(vec3<f32>(uv.x, uv.y, -1.0));
    let light_dir = normalize(vec3<f32>(1.0, 1.0, 1.0));

    var t: f32 = 0.0;
    for (var i: i32 = 0; i < 64; i++) {
        let p = u.camera_pos + rd * t;
        let d = scene(p);
        if d < 0.001 {
            let n = calc_normal(p);
            let diff = max(dot(n, light_dir), 0.0);
            let sha = soft_shadow(p + n * 0.002, light_dir, 0.01, 20.0, 16.0);
            let ao = calc_ao(p, n);
            let ambient = 0.08 * ao;
            let col = vec3<f32>(diff * sha * ao + ambient);
            return vec4<f32>(col, 1.0);
        }
        t += d;
        if t > 100.0 { break; }
    }
    return vec4<f32>(0.05, 0.05, 0.1, 1.0);
}

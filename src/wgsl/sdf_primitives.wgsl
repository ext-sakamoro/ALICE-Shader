// ═══ SDF Primitives (WGSL) ═══

fn sd_box(p: vec3<f32>, b: vec3<f32>) -> f32 {
    let q = abs(p) - b;
    return length(max(q, vec3<f32>(0.0))) + min(max(q.x, max(q.y, q.z)), 0.0);
}

fn sd_round_box(p: vec3<f32>, b: vec3<f32>, r: f32) -> f32 {
    let q = abs(p) - b + r;
    return length(max(q, vec3<f32>(0.0))) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

fn sd_sphere(p: vec3<f32>, r: f32) -> f32 {
    return length(p) - r;
}

fn sd_torus(p: vec3<f32>, t: vec2<f32>) -> f32 {
    let q = vec2<f32>(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

fn sd_octahedron(p_in: vec3<f32>, s: f32) -> f32 {
    let p = abs(p_in);
    return (p.x + p.y + p.z - s) * 0.57735027;
}

fn sd_cylinder(p: vec3<f32>, h: f32, r: f32) -> f32 {
    let d = abs(vec2<f32>(length(p.xz), p.y)) - vec2<f32>(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2<f32>(0.0)));
}

fn sd_gyroid(p_in: vec3<f32>, sc: f32, th: f32) -> f32 {
    let inv_sc = 1.0 / sc;
    let p = p_in * sc;
    return abs(dot(sin(p), cos(p.zxy))) * inv_sc - th;
}

fn smin(a: f32, b: f32, k: f32) -> f32 {
    let inv_k = 1.0 / k;
    let h = max(k - abs(a - b), 0.0);
    return min(a, b) - h * h * 0.25 * inv_k;
}

fn rot2(angle: f32) -> mat2x2<f32> {
    let c = cos(angle);
    let s = sin(angle);
    return mat2x2<f32>(c, -s, s, c);
}

fn disp(p: vec3<f32>) -> f32 {
    return sin(p.x * 2.1 + p.z * 0.7) * sin(p.y * 1.3 + p.z * 0.9) * 0.5
         + sin(p.z * 3.2 - p.x * 1.1) * sin(p.y * 2.7) * 0.25;
}

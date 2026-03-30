// ═══ Noise (WGSL) ═══

fn hash2(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453);
}

fn hash3(p: vec3<f32>) -> f32 {
    return fract(sin(dot(p, vec3<f32>(127.1, 311.7, 74.7))) * 43758.5453);
}

fn vnoise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    var f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    let a = hash2(i);
    let b = hash2(i + vec2<f32>(1.0, 0.0));
    let c = hash2(i + vec2<f32>(0.0, 1.0));
    let d = hash2(i + vec2<f32>(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

fn vnoise3(p: vec3<f32>) -> f32 {
    let i = floor(p);
    var f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    let n00 = mix(hash3(i), hash3(i + vec3<f32>(1.0, 0.0, 0.0)), f.x);
    let n10 = mix(hash3(i + vec3<f32>(0.0, 1.0, 0.0)), hash3(i + vec3<f32>(1.0, 1.0, 0.0)), f.x);
    let n01 = mix(hash3(i + vec3<f32>(0.0, 0.0, 1.0)), hash3(i + vec3<f32>(1.0, 0.0, 1.0)), f.x);
    let n11 = mix(hash3(i + vec3<f32>(0.0, 1.0, 1.0)), hash3(i + vec3<f32>(1.0, 1.0, 1.0)), f.x);
    return mix(mix(n00, n10, f.y), mix(n01, n11, f.y), f.z);
}

fn fbm2(p_in: vec2<f32>) -> f32 {
    var v = 0.0;
    var a = 0.5;
    var p = p_in;
    for (var i: i32 = 0; i < 3; i++) {
        v += a * vnoise(p);
        let px = p.x * 0.8 + p.y * 0.6;
        let py = p.x * -0.6 + p.y * 0.8;
        p = vec2<f32>(px, py) * 2.1;
        a *= 0.48;
    }
    return v;
}

fn fbm3(p_in: vec3<f32>) -> f32 {
    var v = 0.0;
    var a = 0.5;
    var p = p_in;
    for (var i: i32 = 0; i < 3; i++) {
        v += a * vnoise3(p);
        p = p * 2.15 + vec3<f32>(1.7, 3.2, 2.8);
        a *= 0.45;
    }
    return v;
}

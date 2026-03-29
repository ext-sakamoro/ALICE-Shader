struct SkyUniforms {
    camera_pos: vec3<f32>,
    _pad0: f32,
    sun_dir: vec3<f32>,
    day_phase: f32,
    resolution: vec2<f32>,
    fog: f32,
    time: f32,
};

@group(0) @binding(0) var<uniform> u: SkyUniforms;

fn smoothstep_f(e0: f32, e1: f32, x: f32) -> f32 {
    let t = clamp((x - e0) / (e1 - e0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    let uv = (frag_coord.xy / u.resolution) * 2.0 - 1.0;
    let rd = normalize(vec3<f32>(uv.x, uv.y * 0.5 + 0.3, -1.0));
    let y = max(rd.y, 0.001);
    let mu = dot(rd, u.sun_dir);
    let sunH = u.sun_dir.y;
    let dayF = u.day_phase;

    // Rayleigh
    let bR = vec3<f32>(0.0058, 0.0135, 0.0331);
    let bM = 0.021;
    let cosZ = y + 0.001;
    let am = 1.0 / (cosZ + 0.15 * pow(cosZ, 0.6));
    let sunAm = 1.0 / (max(sunH, 0.0) + 0.001 + 0.15 * pow(max(sunH, 0.0) + 0.001, 0.6));
    let densR = exp(-max(rd.y, 0.0) * 3.0);
    let extR = exp(-bR * sunAm * 1.5);
    let phR = 0.059683 * (1.0 + mu * mu);
    var rayleigh = bR * phR * am * densR * extR;

    // Mie
    let g = 0.76;
    let denom = max(1.0 + g * g - 2.0 * g * mu, 0.0001);
    let invSqrt = inverseSqrt(denom);
    let phM = 0.079577 * (1.0 - g * g) * invSqrt * invSqrt * invSqrt;
    let mie = vec3<f32>(bM * phM * am * 0.5 * exp(-max(rd.y, 0.0) * 1.2)) * extR;

    // Sun intensity
    let sunFade = smoothstep_f(-0.08, 0.15, sunH);
    let sunI = vec3<f32>(22.0, 20.0, 17.0) * sunFade;
    var sky = (rayleigh + mie) * sunI;

    // Ambient
    sky += vec3<f32>(0.003, 0.004, 0.005) * max(rd.y, 0.0) * dayF;

    // Sun disc
    let sunAng = acos(clamp(mu, -1.0, 1.0));
    let sunDisc = smoothstep_f(0.006, 0.002, sunAng);
    sky += vec3<f32>(12.0, 10.0, 7.0) * sunDisc * sunFade;

    // Night
    let nightF = 1.0 - dayF;
    sky += vec3<f32>(0.001, 0.002, 0.005) * nightF;

    // Fog
    let fogT = mix(vec3<f32>(0.02, 0.025, 0.04), vec3<f32>(0.3, 0.33, 0.38), dayF);
    sky = mix(sky, fogT, u.fog * 0.55);

    return vec4<f32>(clamp(sky, vec3<f32>(0.0), vec3<f32>(1.0)), 1.0);
}

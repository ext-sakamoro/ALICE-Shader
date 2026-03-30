// ═══ Sky (Physical Rayleigh/Mie + Stars + Moon + Clouds) ═══

struct SkyUniforms {
    camera_pos: vec3<f32>,
    _pad0: f32,
    sun_dir: vec3<f32>,
    day_phase: f32,
    moon_dir: vec3<f32>,
    fog: f32,
    resolution: vec2<f32>,
    time: f32,
    _pad2: f32,
};

@group(0) @binding(0) var<uniform> u: SkyUniforms;

fn sky_hash2(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453);
}

fn sky_hash3(p: vec3<f32>) -> f32 {
    return fract(sin(dot(p, vec3<f32>(127.1, 311.7, 74.7))) * 43758.5453);
}

fn sky_vnoise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    var f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(sky_hash2(i), sky_hash2(i + vec2<f32>(1.0, 0.0)), f.x),
        mix(sky_hash2(i + vec2<f32>(0.0, 1.0)), sky_hash2(i + vec2<f32>(1.0, 1.0)), f.x),
        f.y
    );
}

fn sky_fbm(p_in: vec2<f32>) -> f32 {
    var v = 0.0;
    var a = 0.5;
    var p = p_in;
    for (var i: i32 = 0; i < 3; i++) {
        v += a * sky_vnoise(p);
        let px = p.x * 0.8 + p.y * 0.6;
        let py = p.x * -0.6 + p.y * 0.8;
        p = vec2<f32>(px, py) * 2.1;
        a *= 0.48;
    }
    return v;
}

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
    let nightF = 1.0 - dayF;
    let goldenF = exp(-sunH * sunH * 12.0) * smoothstep_f(-0.15, 0.05, sunH);

    // ── Chapman optical depth ──
    let bR = vec3<f32>(0.0058, 0.0135, 0.0331);
    let bM = 0.021;
    let cosZ = y + 0.001;
    let am = 1.0 / (cosZ + 0.15 * pow(cosZ, 0.6));
    let sunCZ = max(sunH, 0.0) + 0.001;
    let sunAm = 1.0 / (sunCZ + 0.15 * pow(sunCZ, 0.6));
    let densR = exp(-max(rd.y, 0.0) * 3.0);
    let densM = exp(-max(rd.y, 0.0) * 1.2);
    let extR = exp(-bR * sunAm * 1.5);
    let extM = exp(-bM * sunAm * 0.8);

    // ── Rayleigh ──
    let phR = 0.059683 * (1.0 + mu * mu);
    let rayleigh = bR * phR * am * densR * extR;

    // ── Mie ──
    let g = 0.76;
    let g2 = g * g;
    let denom = max(1.0 + g2 - 2.0 * g * mu, 0.0001);
    let invSqrt = inverseSqrt(denom);
    let phM = 0.079577 * (1.0 - g2) * invSqrt * invSqrt * invSqrt;
    let mie = vec3<f32>(bM * phM * am * 0.5 * densM) * extR * extM;

    // ── Ozone absorption (blue moment) ──
    let bO = vec3<f32>(0.00065, 0.0019, 0.00005);
    let ozoneAm = 1.0 / (max(sunH + 0.1, 0.001) + 0.05);
    let ozoneF = smoothstep_f(-0.1, -0.02, sunH) * smoothstep_f(0.15, 0.04, sunH);
    let ozoneExt = exp(-bO * ozoneAm * 5.0) * ozoneF;

    // ── Combined atmosphere ──
    let sunFade = smoothstep_f(-0.08, 0.15, sunH);
    var sunI = vec3<f32>(22.0, 20.0, 17.0) * sunFade;
    sunI *= mix(vec3<f32>(1.0), ozoneExt + vec3<f32>(0.3, 0.2, 0.8), ozoneF);
    var sky = (rayleigh + mie) * sunI;
    sky *= mix(vec3<f32>(1.0), vec3<f32>(0.7, 0.75, 1.3), ozoneF * 0.4);
    sky += vec3<f32>(0.001, 0.004, 0.025) * ozoneF * smoothstep_f(-0.1, 0.3, y);
    sky += vec3<f32>(0.003, 0.004, 0.005) * smoothstep_f(-0.3, 0.2, y) * dayF;

    // ── Sun disc (limb darkening) ──
    let sunAng = acos(clamp(mu, -1.0, 1.0));
    let sunR = 0.0046;
    let sunDisc = smoothstep_f(sunR * 1.3, sunR * 0.4, sunAng);
    let limbT = min(sunAng / sunR, 1.0);
    let limb = 1.0 - 0.6 * (1.0 - sqrt(max(1.0 - limbT * limbT, 0.0)));
    sky += vec3<f32>(12.0, 10.0, 7.0) * sunDisc * max(limb, 0.0) * smoothstep_f(-0.05, 0.05, sunH);
    sky += vec3<f32>(0.4, 0.3, 0.15) * pow(max(mu, 0.0), 128.0) * 0.6 * smoothstep_f(-0.02, 0.1, sunH);

    // ── Golden hour bloom ──
    sky += vec3<f32>(0.35, 0.12, 0.03) * goldenF * exp(-abs(y) * 3.0) * 0.5;
    sky += vec3<f32>(0.6, 0.25, 0.08) * goldenF * pow(max(mu, 0.0), 4.0) * 0.2;

    // ── Moon ──
    let moonDot = max(dot(rd, u.moon_dir), 0.0);
    let moonAng = acos(clamp(dot(rd, u.moon_dir), -1.0, 1.0));
    let moonDisc = smoothstep_f(0.009, 0.003, moonAng);
    sky += vec3<f32>(0.5, 0.55, 0.65) * moonDisc * nightF * 1.5;
    sky += vec3<f32>(0.1, 0.12, 0.18) * pow(moonDot, 24.0) * 0.2 * nightF;

    // ── Stars ──
    let sid = floor(rd * 420.0);
    let ss = sky_hash3(sid);
    let mag = pow(ss, 0.25);
    var starB = smoothstep_f(0.88, 1.0, mag);
    starB *= 0.5 + 0.5 * sin(u.time * (sky_hash3(sid + 200.0) * 3.5 + 0.5));
    let bv = sky_hash3(sid + 300.0);
    let starC = mix(
        mix(vec3<f32>(0.6, 0.7, 1.0), vec3<f32>(1.0, 0.97, 0.93), smoothstep_f(0.0, 0.4, bv)),
        mix(vec3<f32>(1.0, 0.85, 0.65), vec3<f32>(1.0, 0.6, 0.35), smoothstep_f(0.5, 1.0, bv)),
        smoothstep_f(0.35, 0.55, bv)
    );
    sky += starC * starB * 0.5 * nightF * smoothstep_f(0.0, 0.08, y);

    // ── Milky Way ──
    let mwDot = abs(dot(rd, normalize(vec3<f32>(0.3, 0.7, 0.15))));
    let mwAng = acos(clamp(mwDot, 0.0, 1.0));
    let mwBand = exp(-(mwAng - 0.2) * (mwAng - 0.2) * 6.0);
    sky += vec3<f32>(0.045, 0.03, 0.06) * mwBand * sky_vnoise(rd.xz * 3.5 + rd.y * 2.0) * nightF * smoothstep_f(0.05, 0.35, y);

    // ── Volumetric Clouds (Cumulus + Cirrus) ──
    if y > 0.008 {
        let invY = 1.0 / y;
        // Cumulus
        let cUV = rd.xz * invY * 0.12 + u.time * vec2<f32>(0.003, 0.001);
        let cn = sky_fbm(cUV * 4.0);
        let cn2 = sky_vnoise(cUV * 16.0 + 30.0);
        let cover = 0.08 + u.fog * 0.35;
        let cD = smoothstep_f(0.4 - cover, 0.7, cn + cn2 * 0.15) * smoothstep_f(0.008, 0.12, y);
        var cLit = smoothstep_f(0.35, 0.75, cn) * 0.6 + 0.4;
        cLit *= max(sunH + 0.2, 0.08);
        var cBr = mix(vec3<f32>(0.04, 0.045, 0.06), vec3<f32>(1.0, 0.95, 0.85), dayF) * cLit;
        var cDk = mix(vec3<f32>(0.012, 0.015, 0.025), vec3<f32>(0.3, 0.3, 0.35), dayF);
        cBr += vec3<f32>(1.0, 0.45, 0.15) * goldenF * 0.8;
        cDk += vec3<f32>(0.5, 0.2, 0.08) * goldenF * 0.3;
        let edge = smoothstep_f(0.55, 0.45, cn) * smoothstep_f(0.3, 0.4, cn);
        let cCol = mix(cDk, cBr, cLit) + vec3<f32>(0.7, 0.65, 0.55) * edge * dayF * 0.25;
        sky = mix(sky, cCol, clamp(cD, 0.0, 1.0));
        // Cirrus
        let ciUV = rd.xz * invY * 0.05 + u.time * vec2<f32>(0.005, 0.002);
        let ci = sky_fbm(ciUV * 10.0);
        let ciD = smoothstep_f(0.52, 0.78, ci) * 0.3 * smoothstep_f(0.1, 0.35, y);
        let ciC = mix(vec3<f32>(0.025, 0.03, 0.04), vec3<f32>(0.55, 0.55, 0.6), dayF) + vec3<f32>(0.4, 0.2, 0.08) * goldenF * 0.4;
        sky = mix(sky, ciC, clamp(ciD, 0.0, 1.0));
    }

    // ── Fog ──
    let fogT = mix(vec3<f32>(0.02, 0.025, 0.04), vec3<f32>(0.3, 0.33, 0.38), dayF);
    sky = mix(sky, fogT, u.fog * 0.55);

    return vec4<f32>(max(sky, vec3<f32>(0.0)), 1.0);
}

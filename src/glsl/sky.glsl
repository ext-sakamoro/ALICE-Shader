// ═══ Sky (Physical Rayleigh/Mie + Volumetric Clouds) ═══
vec3 skyColor(vec3 rd,vec3 sunDir,vec3 moonDir,float dayF){
  float y=rd.y;
  float mu=dot(rd,sunDir);
  float sunH=sunDir.y;
  float nightF=1.0-dayF;
  float goldenF=exp(-sunH*sunH*12.0)*smoothstep(-0.15,0.05,sunH);

  // ── Chapman function optical depth ──
  // Scale heights: Rayleigh H_R=8.0km (~normalized), Mie H_M=1.2km
  vec3 bR=vec3(5.8,13.5,33.1)*1e-3;
  float bM=0.021;
  float cosZ=max(y,0.0)+0.001;
  float sunCZ=max(sunH,0.0)+0.001;
  // Chapman approximation: Ch(x,chi) ~ sqrt(PI*x/2) * (1/cosZ) for cosZ>0
  // Simplified: am = 1/(cosZ + 0.15*cosZ^(3/5)) — Schaefer polynomial
  float cosZ35=pow(cosZ,0.6);
  float am=1.0/(cosZ+0.15*cosZ35);
  float sunCZ35=pow(sunCZ,0.6);
  float sunAm=1.0/(sunCZ+0.15*sunCZ35);
  // Dual-scale optical depth (Rayleigh deeper, Mie shallower)
  float densR=exp(-max(y,0.0)*3.0);    // H_R scale
  float densM=exp(-max(y,0.0)*1.2);    // H_M scale (lower = thicker near horizon)
  vec3 extR=exp(-bR*sunAm*1.5);
  float extM=exp(-bM*sunAm*0.8);

  // ── Rayleigh Scattering ──
  float phR=0.059683*(1.0+mu*mu);
  vec3 rayleigh=bR*phR*am*densR*extR;

  // ── Mie Scattering ──
  float g=0.76,g2=g*g;
  float denomMie=max(1.0+g2-2.0*g*mu,0.0001);
  float denomSqrt=inversesqrt(denomMie);
  float phM=0.079577*(1.0-g2)*denomSqrt*denomSqrt*denomSqrt;
  vec3 mie=vec3(bM*phM*(am*0.5)*densM)*extR*extM;

  // ── Ozone absorption (blue moment) ──
  // Ozone Chappuis band absorbs 500-700nm (green-red), leaving blue at twilight
  vec3 bO=vec3(0.065,0.19,0.005)*1e-2; // ozone cross-section (R,G,B)
  float ozoneAm=1.0/(max(sunH+0.1,0.001)+0.05); // deep airmass at twilight
  float ozoneF=smoothstep(-0.1,-0.02,sunH)*smoothstep(0.15,0.04,sunH); // twilight window
  vec3 ozoneExt=exp(-bO*ozoneAm*5.0)*ozoneF;

  // ── Combined atmosphere ──
  vec3 sunI=vec3(22.0,20.0,17.0)*smoothstep(-0.08,0.15,sunH);
  sunI*=mix(vec3(1),ozoneExt+vec3(0.3,0.2,0.8),ozoneF); // ozone absorption on sun path
  vec3 sky=(rayleigh+mie)*sunI;
  // Blue moment: residual ozone blue fill at civil twilight
  sky*=mix(vec3(1),vec3(0.7,0.75,1.3),ozoneF*0.4);
  sky+=vec3(0.001,0.004,0.025)*ozoneF*smoothstep(-0.1,0.3,y); // deep blue fill
  sky+=vec3(0.0,0.003,0.015)*max(y,0.0)*dayF;
  sky+=vec3(0.003,0.004,0.005)*smoothstep(-0.3,0.2,y)*dayF;

  // ── Sun disc (limb darkening) ──
  float sunAng=acos(clamp(mu,-1.0,1.0));
  float sunR=0.0046;
  float sunDisc=smoothstep(sunR*1.3,sunR*0.4,sunAng);
  float limbT=min(sunAng/sunR,1.0);
  float limb=1.0-0.6*(1.0-sqrt(max(1.0-limbT*limbT,0.0)));
  sky+=vec3(12.0,10.0,7.0)*sunDisc*max(limb,0.0)*smoothstep(-0.05,0.05,sunH);
  sky+=vec3(0.4,0.3,0.15)*pow(max(mu,0.0),128.0)*0.6*smoothstep(-0.02,0.1,sunH);

  // ── Golden hour bloom ──
  sky+=vec3(0.35,0.12,0.03)*goldenF*exp(-abs(y)*3.0)*0.5;
  sky+=vec3(0.6,0.25,0.08)*goldenF*pow(max(mu,0.0),4.0)*0.2;

  // ── Moon ──
  float moonDot=max(dot(rd,moonDir),0.0);
  float moonAng=acos(clamp(dot(rd,moonDir),-1.0,1.0));
  float moonDisc=smoothstep(0.009,0.003,moonAng);
  sky+=vec3(0.5,0.55,0.65)*moonDisc*nightF*1.5;
  sky+=vec3(0.1,0.12,0.18)*pow(moonDot,24.0)*0.2*nightF;

  // ── Stars (magnitude-based, spectral color) ──
  vec3 sid=floor(rd*420.0);
  float ss=hash3(sid);
  float mag=pow(ss,0.25);
  float starB=smoothstep(0.88,1.0,mag);
  starB*=0.5+0.5*sin(uTime*(hash3(sid+200.0)*3.5+0.5));
  float bv=hash3(sid+300.0);
  vec3 starC=mix(
    mix(vec3(0.6,0.7,1.0),vec3(1.0,0.97,0.93),smoothstep(0.0,0.4,bv)),
    mix(vec3(1.0,0.85,0.65),vec3(1.0,0.6,0.35),smoothstep(0.5,1.0,bv)),
    smoothstep(0.35,0.55,bv));
  sky+=starC*starB*0.5*nightF*smoothstep(0.0,0.08,y);

  // ── Milky Way ──
  float mwDot=abs(dot(rd,normalize(vec3(0.3,0.7,0.15))));
  float mwAng=acos(clamp(mwDot,0.0,1.0));
  float mwBand=exp(-(mwAng-0.2)*(mwAng-0.2)*6.0);
  sky+=vec3(0.045,0.03,0.06)*mwBand*vnoise(rd.xz*3.5+rd.y*2.0)*nightF*smoothstep(0.05,0.35,y);

  // ── Nebula ──
  sky+=vec3(0.07,0.012,0.11)*vnoise(rd.xz*2.5+rd.y*1.5)*0.13*(1.0-abs(y))*nightF;
  sky+=vec3(0.012,0.04,0.09)*vnoise(rd.xz*3.5-rd.y*2.0+100.0)*0.09*(1.0-abs(y))*nightF;

  // ── Aurora ──
  float aurora=smoothstep(0.2,0.55,y)*smoothstep(0.8,0.45,y);
  float aN=vnoise(vec2(rd.x*4.0+uTime*0.08,rd.z*2.5+uTime*0.04));
  sky+=vec3(0.0,0.18,0.08)*aurora*aN*0.2*nightF;
  sky+=vec3(0.06,0.0,0.1)*aurora*(1.0-aN)*0.08*nightF;

  // ── Volumetric Clouds (dual layer) ──
  if(y>0.008){
    float invY=1.0/y;
    // Cumulus
    vec2 cUV=rd.xz*invY*0.12+uTime*vec2(0.003,0.001);
    float cn=fbm(cUV*4.0);
    float cn2=vnoise(cUV*16.0+30.0);
    float cover=0.08+uWxFog*0.35+uWxRain*0.4;
    float cD=smoothstep(0.4-cover,0.7,cn+cn2*0.15)*smoothstep(0.008,0.12,y);
    float cLit=smoothstep(0.35,0.75,cn)*0.6+0.4;
    cLit*=max(sunH+0.2,0.08);
    vec3 cBr=mix(vec3(0.04,0.045,0.06),vec3(1.0,0.95,0.85),dayF)*cLit;
    vec3 cDk=mix(vec3(0.012,0.015,0.025),vec3(0.3,0.3,0.35),dayF);
    cDk=mix(cDk,cDk*0.25,uWxRain*0.7);
    cBr+=vec3(1.0,0.45,0.15)*goldenF*0.8;
    cDk+=vec3(0.5,0.2,0.08)*goldenF*0.3;
    float edge=smoothstep(0.55,0.45,cn)*smoothstep(0.3,0.4,cn);
    vec3 cCol=mix(cDk,cBr,cLit)+vec3(0.7,0.65,0.55)*edge*dayF*0.25;
    sky=mix(sky,cCol,SAT(cD));
    // Cirrus
    vec2 ciUV=rd.xz*invY*0.05+uTime*vec2(0.005,0.002);
    float ci=fbm(ciUV*10.0);
    float ciD=smoothstep(0.52,0.78,ci)*0.3*smoothstep(0.1,0.35,y);
    vec3 ciC=mix(vec3(0.025,0.03,0.04),vec3(0.55,0.55,0.6),dayF)+vec3(0.4,0.2,0.08)*goldenF*0.4;
    sky=mix(sky,ciC,SAT(ciD));
  }

  // ── Fog ──
  vec3 fogT=mix(vec3(0.02,0.025,0.04),vec3(0.3,0.33,0.38),dayF);
  sky=mix(sky,fogT,uWxFog*0.55);
  return max(sky,vec3(0));
}


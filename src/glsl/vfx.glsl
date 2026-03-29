// ═══ VFX Foundation (ALICE-VFX Recipe) ═══
// Blackbody radiation — temperature(K) to physically correct color
vec3 blackbody(float K){
  float t=K*0.01;
  float hi=step(66.0,t);float lo=1.0-hi;
  float r=mix(1.0,SAT(1.292936*inversesqrt(max(t-55.0,0.001))-0.16),hi);
  float g=mix(SAT(0.39008*log(max(t,1.0))-0.63184),SAT(1.129891*inversesqrt(max(t-50.0,0.001))-0.15),hi);
  float warm=step(19.0,t);
  float b=mix(SAT(0.54321*log(max(t-10.0,1.0))-1.19625)*warm,1.0,hi);
  return vec3(r,g,b);
}
// Spectral rendering — CIE 1931 2-deg observer approximation (wavelength nm → linear RGB)
vec3 spectralToRGB(float lambda){
  // Gaussian fit to CIE xyz color matching functions
  float x=1.056*exp(-0.5*pow((lambda-599.8)*0.0244,2.0))+0.362*exp(-0.5*pow((lambda-442.0)*0.0624,2.0))-0.065*exp(-0.5*pow((lambda-501.1)*0.049,2.0));
  float y=0.821*exp(-0.5*pow((lambda-568.8)*0.0213,2.0))+0.286*exp(-0.5*pow((lambda-530.9)*0.0613,2.0));
  float z=1.217*exp(-0.5*pow((lambda-437.0)*0.0845,2.0))+0.681*exp(-0.5*pow((lambda-459.0)*0.0385,2.0));
  // CIE XYZ → sRGB linear (D65)
  return vec3(3.2406*x-1.5372*y-0.4986*z,-0.9689*x+1.8758*y+0.0415*z,0.0557*x-0.2040*y+1.0570*z);
}
// Spectral integration — evaluate blackbody S(lambda) over visible range (380-720nm, 8 samples)
vec3 spectralBlackbody(float K){
  vec3 acc=vec3(0);
  float invK=1.0/(K+0.001);
  for(int i=0;i<4;i++){
    float lambda=380.0+float(i)*113.3; // 380 to 720nm, 4サンプル
    // Planck's law (simplified): S(λ) ∝ λ^-5 / (exp(hc/λkT) - 1)
    float lm=lambda*1e-3; // micro-scale for numerical stability
    float x=1.4388e3*invK/(lambda+0.001); // hc/kT * 1/lambda (in nm)
    float planck=1.0/(lm*lm*lm*lm*lm*(exp(min(x,80.0))-1.0)+0.001);
    acc+=spectralToRGB(lambda)*planck;
  }
  return max(acc*0.00025,vec3(0)); // normalize (4サンプル補正)
}
// Rayleigh spectral sky — wavelength-dependent λ^-4 scattering
vec3 rayleighSpectral(float mu,float am,float densR,vec3 extR){
  vec3 acc=vec3(0);
  for(int i=0;i<4;i++){
    float lambda=400.0+float(i)*100.0; // 400-700nm, 4サンプル
    float scatter=1.0/(lambda*lambda*lambda*lambda)*1e10; // λ^-4
    float phR=0.059683*(1.0+mu*mu);
    vec3 rgb=spectralToRGB(lambda);
    acc+=rgb*scatter*phR*am*densR;
  }
  return max(acc*extR*0.012,vec3(0)); // 4サンプル補正
}
// Micro-FBM — nanoscale thermal vibration displacement for atomic-level surface detail
vec3 microNormal(vec3 p,vec3 n,float freq,float amp){
  vec2 e=vec2(0.001,0);
  float d0=vnoise3(p*freq);
  float dx=vnoise3((p+e.xyy)*freq)-d0;
  float dy=vnoise3((p+e.yxy)*freq)-d0;
  float dz=vnoise3((p+e.yyx)*freq)-d0;
  return normalize(n+vec3(dx,dy,dz)*(amp/(e.x+0.0001)));
}
// Analytic bloom — SDF distance-based glow (no blur pass)
vec3 aBloom(float d,vec3 gc,float intensity,float falloff){
  return gc*exp(-abs(d)*falloff)*intensity;
}
// Domain warp — 2-pass analytic spatial distortion
vec3 dWarp(vec3 p,float t,float intensity){
  float fx=sin(p.y*1.7+t*0.3);float fy=cos(p.z*1.3+t*0.5);float fz=sin(p.x*2.1+t*0.4);
  return p+vec3(fx,fy,fz)*intensity;
}
// Dielectric Breakdown Model — fractal space-folding discharge
float dbmDischarge(vec3 p,vec3 src,float charge,float t){
  vec3 dir=normalize(p-src);float dist=length(p-src);
  float discharge=0.0;float amp=1.0;vec3 q=p;
  for(int i=0;i<6;i++){
    q=abs(q)-dir*0.5*amp;
    float ca=cos(charge*float(i)+t);float sa=sin(charge*float(i)+t);
    q.xy=vec2(q.x*ca-q.y*sa,q.x*sa+q.y*ca);
    discharge+=(1.0/(length(q.xz)+0.01))*amp;
    amp*=0.5;
  }
  return discharge*exp(-dist*0.5)*charge;
}


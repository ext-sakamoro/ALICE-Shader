// ═══ Biome System (真理の地形法 — ズートピア型ラジアル配置) ═══
// 角度ベースセクター + 中央ハブ融合 (step/floor完全不使用)
// vec4: x=雪(NE 12-3時), y=砂漠(SW 6-9時), z=岩石(SE 3-6時), w=草原(NW 9-12時)
float angleDist(float a,float b){
  float d=a-b;
  d=d-TAU*floor((d+PI)/TAU); // wrap to -PI..PI
  return abs(d);
}
vec4 biomeWeights(vec2 xz){
  float dist=length(xz);
  float ang=atan(xz.y,xz.x); // -PI..PI
  // セクター中心角 (上から時計回り)
  // NE(12-3時)=+PI/4, SE(3-6時)=-PI/4, SW(6-9時)=-3PI/4, NW(9-12時)=+3PI/4
  float aSnow=PI*0.25;
  float aRock=-PI*0.25;
  float aDesert=-PI*0.75;
  float aGrass=PI*0.75;
  // 角度距離のガウシアン重み (シャープネス=3.0 → 90°セクターにフィット)
  float wS=exp(-angleDist(ang,aSnow)*angleDist(ang,aSnow)*3.0);
  float wR=exp(-angleDist(ang,aRock)*angleDist(ang,aRock)*3.0);
  float wD=exp(-angleDist(ang,aDesert)*angleDist(ang,aDesert)*3.0);
  float wG=exp(-angleDist(ang,aGrass)*angleDist(ang,aGrass)*3.0);
  // 中央ハブ: 半径8m以内は全バイオーム均等融合
  float hub=smoothstep(12.0,5.0,dist);
  wS=mix(wS,1.0,hub);wR=mix(wR,1.0,hub);
  wD=mix(wD,1.0,hub);wG=mix(wG,1.0,hub);
  // 正規化
  float invSum=1.0/(wS+wR+wD+wG+0.001);
  return vec4(wS,wD,wR,wG)*invSum;
}

// Voronoi侵食 (岩石バイオーム用)
float voronoiErosion(vec2 p){
  vec2 n=floor(p);vec2 f=fract(p);
  float md=8.0,md2=8.0;
  for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++){
    vec2 g=vec2(float(i),float(j));
    vec2 o=vec2(hash(n+g),hash(n+g+vec2(31.3,17.7)));
    vec2 r=g+o-f;float d=dot(r,r);
    float sel=step(d,md);md2=mix(md2,md,sel);md=mix(md,d,sel);
  }
  // 侵食: 鋭利な断面 (md2-md edge)
  float edge=sqrt(md2)-sqrt(md);
  return sqrt(md)*0.6-edge*0.8;
}

// バイオーム別地形高さ (真理の地形法)
float terrainHeight(vec2 xz){
  vec4 w=biomeWeights(xz);
  // 雪: fbm + 青色ノイズ積雪 (uTime除去 — JS側と同期)
  float hSnow=fbm(xz*0.12)*1.5+vnoise(xz*0.3)*0.4;
  // 砂漠: 風ベクトル場の風紋 (固定風向 — JS側と同期)
  vec2 windDir=vec2(0.8,0.6);
  float windProj=dot(xz*0.08,windDir);
  float windPerp=dot(xz*0.08,vec2(-windDir.y,windDir.x));
  float hDesert=fbm(vec2(windProj*3.0,windPerp*0.8))*0.8+vnoise(xz*0.06)*0.5;
  // 岩石: Voronoi侵食
  float hRock=voronoiErosion(xz*0.15)*2.2;
  // 草原: FBM起伏
  float hGrass=fbm(xz*0.1)*1.0+vnoise(xz*0.2)*0.25;
  float h=w.x*hSnow+w.y*hDesert+w.z*hRock+w.w*hGrass;
  // 建築エリア平坦化 (base平板と自然に接続)
  float bFlat=smoothstep(10.0,6.0,length(xz));
  bFlat=max(bFlat,smoothstep(7.0,3.0,length(xz-vec2(0,-35))));
  bFlat=max(bFlat,smoothstep(5.0,1.5,length(xz-vec2(35,0))));
  bFlat=max(bFlat,smoothstep(7.0,3.0,length(xz-vec2(0,35))));
  bFlat=max(bFlat,smoothstep(9.0,4.0,length(xz-vec2(-35,0))));
  h*=1.0-bFlat*0.9;
  return h;
}


// ═══ Materials ═══
struct Mat{vec3 albedo;float metallic;float roughness;vec3 emission;float sss;};

Mat getMat(float id,vec3 p){
  Mat m;m.emission=vec3(0);m.sss=0.0;
  int mid=int(id+0.5);
  if(mid==0){
    vec4 bw=biomeWeights(p.xz);
    // ── 雪原 (Lobby): 青色ノイズ積雪 + SSS 0.8 ──
    float snowN=vnoise(p.xz*2.0)*0.03;
    float snowIce=vnoise(p.xz*12.0)*0.02;
    vec3 snowAlb=vec3(0.85+snowN,0.88+snowN+snowIce,0.92+snowN+snowIce*2.0);
    // 氷の面積を極小化、ベースを新雪(0.85)のマットな質感に
    float iceF=smoothstep(0.75,0.9,vnoise(p.xz*6.0)); // ごく一部の凍結面のみ
    float snowRough=mix(0.85,0.2,iceF)+vnoise(p.xz*8.0)*0.05;
    float snowSSS=0.8;
    // ── 砂漠 (Services): 風ベクトル場異方性反射 ──
    float sandN=vnoise(p.xz*6.0)*0.04;
    vec2 wDir=vec2(cos(uTime*0.01),sin(uTime*0.01));
    vec2 wPerp=vec2(-wDir.y,wDir.x);
    float wProj=dot(p.xz,wDir);
    float ripPar=vnoise(vec2(wProj*4.0,dot(p.xz,wPerp)*1.5));
    float ripPer=vnoise(vec2(wProj*1.5,dot(p.xz,wPerp)*4.0));
    vec3 sandAlb=vec3(0.76+sandN,0.62+sandN,0.42+sandN*0.5);
    float sandH=SAT(p.y*0.5+0.5);
    sandAlb=mix(sandAlb,sandAlb*vec3(1.1,0.95,0.85),sandH);
    // 乾燥砂: ベース0.6以上、ふんわりとした光の拡散
    float sandRough=0.6+ripPar*0.2+ripPer*0.1;
    // ── 岩石 (Research): Voronoi侵食SDF勾配→地層色+亀裂 ──
    float rockN=vnoise(p.xz*4.0)*0.06;
    vec3 vr=voronoi2(p.xz*0.8);
    float rockEdge=smoothstep(0.0,0.12,vr.y);
    vec3 rockStrata=mix(vec3(0.18,0.16,0.12),vec3(0.28,0.24,0.22),vr.z);
    vec3 rockAlb=mix(rockStrata*0.6,rockStrata+rockN,rockEdge);
    // 亀裂内=極粗(風化面)、平面=やや滑らか(研磨)
    float rockRough=0.4+vnoise(p.xz*12.0)*0.2+(1.0-rockEdge)*0.35;
    // ── 草原 (Stats): sdCylinder 2層albedo ──
    float grassN=vnoise(p.xz*3.0)*0.05;
    vec3 grassGreen=vec3(0.15+grassN*0.5,0.35+grassN,0.1+grassN*0.3);
    vec3 grassDry=vec3(0.3+grassN,0.28+grassN*0.5,0.12);
    float grassTip=SAT(vnoise(p.xz*8.0)*1.5-0.3);
    vec3 grassAlb=mix(grassGreen,grassDry,grassTip*0.35);
    // 草原マット化: 0.85ベース、テカリ完全消去
    float grassRough=0.85+vnoise(p.xz*10.0)*0.08;
    // ── バイオームブレンド ──
    m.albedo=bw.x*snowAlb+bw.y*sandAlb+bw.z*rockAlb+bw.w*grassAlb;
    m.metallic=bw.z*0.12;
    m.roughness=bw.x*snowRough+bw.y*sandRough+bw.z*rockRough+bw.w*grassRough;
    m.sss=bw.x*snowSSS;
    m.emission=vec3(0);
    // パスグロー (全バイオーム共通、薄く)
    float pathGlow=max(smoothstep(1.0,0.0,abs(p.x)),smoothstep(1.0,0.0,abs(p.z)));
    float pathPulse=sin(length(p.xz)*0.3-uTime*1.5)*0.3+0.7;
    m.emission+=vec3(0.04,0.25,0.55)*pathGlow*0.15*pathPulse;
    // Rain: 全バイオーム共通の濡れ
    m.roughness*=mix(1.0,0.04,uWxRain*0.55);
    if(uWxRain>0.01){
      float splash=0.0;
      for(int i=0;i<3;i++){
        float fi=float(i);
        vec2 cell=floor(p.xz*1.5+fi*7.3);
        vec2 rpos=cell+vec2(hash(cell+fi*13.7),hash(cell+fi*31.1+5.0));
        float dist=length(p.xz*1.5-rpos);
        float phase=fract(uTime*(1.2+fi*0.3)+hash(cell)*6.28);
        float ring=1.0-smoothstep(0.0,0.04,abs(dist-phase*1.8));
        float fade=(1.0-phase)*(1.0-phase);
        splash+=ring*fade;
      }
      splash=min(splash,1.0)*uWxRain;
      m.roughness=mix(m.roughness,0.01,splash*0.6);
      m.emission+=vec3(0.15,0.25,0.45)*splash*0.25;
      // ── 岩場の水たまり (Puddles): Voronoi凹み+低地で鏡面化 ──
      float puddleDepth=smoothstep(0.12,0.0,vr.y)*smoothstep(0.3,0.0,p.y);
      float puddle=bw.z*puddleDepth*uWxRain;
      m.roughness=mix(m.roughness,0.01,puddle);
      m.albedo=mix(m.albedo,m.albedo*0.6,puddle); // 水面は暗く
    }
  }else if(mid==1){
    // Energy Orb — branchless zone color via step masks
    float zN=step(p.z,-20.0);float xP=step(20.0,p.x)*(1.0-zN);float zP=step(20.0,p.z)*(1.0-zN)*(1.0-xP);float xN=step(p.x,-20.0)*(1.0-zN)*(1.0-xP)*(1.0-zP);float ctr=1.0-zN-xP-zP-xN;
    vec3 oC1=vec3(0.1,0.25,1.0)*zN+vec3(0.0,0.55,0.7)*xP+vec3(0.85,0.55,0.05)*zP+vec3(0.7,0.06,0.4)*xN+vec3(0.4,0.06,0.7)*ctr;
    vec3 oC2=vec3(0.35,0.65,1.5)*zN+vec3(0.15,0.85,1.0)*xP+vec3(1.0,0.8,0.2)*zP+vec3(1.0,0.2,0.7)*xN+vec3(0.6,0.2,1.0)*ctr;
    // Domain warp: 2-pass analytic distortion for organic plasma surface
    vec3 wp=dWarp(p,uTime*0.8,0.6);
    float pl=fbm3(wp*2.0+uTime*0.5);float pu=sin(uTime*2.5+pl*5.0)*0.5+0.5;
    m.albedo=mix(oC1,oC2,pl)*0.2;m.metallic=0.1;m.roughness=0.04;
    m.emission=mix(oC1,oC2,pl)*(1.8+pu*1.2);
    // Dielectric Breakdown Model: fractal space-folding discharge
    float arc=dbmDischarge(p,p-vec3(0,0.5,0),1.5+sin(uTime*1.8)*0.5,uTime*2.0);
    m.emission+=vec3(1.0,1.0,1.2)*SAT(arc-0.5)*8.0;
    m.emission+=mix(oC1,oC2,0.5)*0.4;m.sss=0.6;
  }else if(mid==2){
    float brush=vnoise(vec2(p.y*40.0,atan(p.x,p.z)*12.0))*0.08;
    m.albedo=vec3(0.74,0.74,0.76)+brush;m.metallic=0.97;m.roughness=0.06+brush*0.4;
    m.emission=vec3(0.04,0.18,0.4)*0.12;
    // Fractal folding micro-detail
    vec3 fp2=abs(fract(p*8.0)-0.5);float fold2=min(fp2.x,min(fp2.y,fp2.z));
    m.roughness+=smoothstep(0.02,0.0,fold2)*0.15;
    m.emission+=vec3(0.02,0.08,0.2)*smoothstep(0.01,0.0,fold2)*0.3;
  }else if(mid==3){
    m.albedo=vec3(0.015,0.03,0.07);m.metallic=0.04;m.roughness=0.015;m.sss=0.55;
    float scan=smoothstep(0.4,0.5,sin(p.y*10.0+uTime*2.0)*0.5+0.5);
    float data=step(0.97,hash(floor(vec2(p.x*4.0,p.y*20.0-uTime*3.0))));
    float edge=1.0-smoothstep(0.0,0.12,abs(fract(p.y*0.2)-0.5));
    m.emission=vec3(0.08,0.25,0.75)*0.35+vec3(0.04,0.12,0.45)*scan*0.35+vec3(0.25,0.6,1.0)*data*0.9+vec3(0.06,0.2,0.65)*edge*0.25;
    // Interior mapping — pseudo-rooms behind glass panels
    vec3 iRoom=interiorMap(p,1.2);m.emission+=iRoom*0.6;
  }else if(mid==4){
    m.albedo=vec3(0.02,0.055,0.075)+vnoise3(p*2.0)*0.015;m.metallic=0.12;m.roughness=0.04;m.sss=0.35;
    m.emission=vec3(0.0,0.38,0.65)*0.28+vec3(0.0,0.5,0.85)*(sin(p.y*4.0)*0.5+0.5)*0.12;
    vec3 iRoom2=interiorMap(p,0.8);m.emission+=iRoom2*0.4;
  }else if(mid==5){
    float d=vnoise3(p*18.0);m.albedo=vec3(0.88,0.68,0.22)+d*0.04;m.metallic=0.94;m.roughness=0.22+d*0.1;
  }else if(mid==6){
    m.albedo=vec3(0.95,0.82,0.35);m.metallic=0.99;m.roughness=0.015;
    float sp=pow(max(sin(p.x*20.0+uTime*4.0)*sin(p.y*20.0-uTime*3.0)*sin(p.z*20.0+uTime*2.0),0.0),8.0);
    m.emission=vec3(0.8,0.55,0.1)*(0.35+0.25*sin(uTime*3.0))+vec3(1.0,0.9,0.6)*sp*0.5;
  }else if(mid==7){
    float pl=vnoise3(p*4.0+vec3(uTime*0.6,uTime*0.4,uTime*0.8));
    m.albedo=vec3(0.2,0.02,0.12);m.metallic=0.45;m.roughness=0.08;
    m.emission=mix(vec3(1.0,0.1,0.55),vec3(0.35,0.1,1.0),pl)*(0.55+0.35*sin(uTime*2.5+pl*5.0));
  }else if(mid==8){
    float pu=sin(uTime*3.0+length(p)*2.5)*0.5+0.5;
    m.albedo=vec3(0.12,0.35,0.55);m.metallic=0.2;m.roughness=0.05;
    m.emission=vec3(0.35,0.7,1.3)*(0.5+pu*0.5);m.sss=0.85;
  }else if(mid==9){
    float d=vnoise3(p*6.0)*0.04;float md=vnoise3(p*40.0)*0.002;m.albedo=vec3(0.04+d+md,0.042+d+md,0.055+d+md);m.metallic=0.88;m.roughness=0.28+md*2.0;
    m.emission=vec3(0.02,0.1,0.22)*0.12;
  }else if(mid==10){
    float md10=vnoise3(p*40.0)*0.002;m.albedo=vec3(0.68+md10,0.7+md10,0.72+md10);m.metallic=0.98;m.roughness=0.04+abs(md10)*3.0;m.emission=vec3(0.04,0.18,0.42)*0.18;
    // Fractal folding ornament
    vec3 fp10=abs(fract(p*12.0)-0.5);float fold10=min(fp10.x,min(fp10.y,fp10.z));
    m.emission+=vec3(0.03,0.12,0.3)*smoothstep(0.015,0.0,fold10)*0.25;
  }else if(mid==11){
    m.albedo=vec3(0.08,0.15,0.25);m.metallic=0.0;m.roughness=0.5;
    m.emission=vec3(0.15,0.55,1.0)*(0.85+0.15*sin(uTime*5.0+p.y*2.0));
  }else if(mid==12){
    m.albedo=vec3(0.01,0.04,0.06);m.metallic=0.05;m.roughness=0.08;m.sss=0.8;
    m.emission=vec3(0.0,0.55,0.9)*0.5*(sin(p.y*2.0+uTime*1.5)*0.5+0.5)+vec3(0.1,0.3,0.7)*0.2;
  }else if(mid<=14){
    // Meteor core — blackbody radiation (8000K core → 3000K surface)
    float plasma=fbm3(p*0.8+vec3(uTime*0.5,uTime*2.5,uTime*0.8));
    float vortex=fbm3(p*1.5+vec3(sin(uTime*0.3)*3.0,uTime*4.0,cos(uTime*0.2)*2.0));
    float coreTemp=mix(8000.0,3000.0,plasma); // temperature gradient
    m.albedo=vec3(0.02);m.metallic=0.0;m.roughness=0.95;
    vec3 bbCol=blackbody(coreTemp);
    m.emission=bbCol*mix(12.0,20.0,plasma)+blackbody(12000.0)*pow(max(vortex,0.0),2.0)*8.0;
  }else if(mid==15){
    // Meteor tail — blackbody cooling gradient (6000K→1500K)
    float streak=fbm3(p*vec3(4.0,0.2,4.0)+vec3(0,uTime*8.0,0));
    float tailTemp=mix(6000.0,1500.0,streak);
    m.albedo=vec3(0.01);m.metallic=0.0;m.roughness=1.0;m.sss=1.0;
    vec3 tailBB=blackbody(tailTemp);
    float pulse=pow(max(sin(p.y*0.5+uTime*3.0)*0.5+0.5,0.0),2.0);
    m.emission=tailBB*mix(8.0,15.0,1.0-streak)+blackbody(4500.0)*pulse*4.0;
  }else if(mid==16){
    m.albedo=vec3(0.96,0.97,1.0);m.metallic=0.02;m.roughness=0.008;m.sss=0.85;
    m.emission=vec3(0.04,0.08,0.15)*0.08;
    float sh=max(uShatter,(uEntropy-0.5)*0.15);
    if(sh>0.005){vec3 fr=fract(p*2.5);vec3 df=min(fr,1.0-fr);float e=min(df.x,min(df.y,df.z));float ck=smoothstep(0.12*sh,0.0,e);m.emission+=mix(vec3(1.5,0.6,0.12),vec3(0.3,0.6,1.2),1.0-uEntropy)*ck*sh*6.0;m.albedo*=1.0-ck*0.3;}
  }else if(mid==17){
    // Energy Ring — branchless zone color via step masks
    float rzN=step(p.z,-20.0);float rxP=step(20.0,p.x)*(1.0-rzN);float rzP=step(20.0,p.z)*(1.0-rzN)*(1.0-rxP);float rxN=step(p.x,-20.0)*(1.0-rzN)*(1.0-rxP)*(1.0-rzP);float rctr=1.0-rzN-rxP-rzP-rxN;
    vec3 rC=vec3(0.25,0.5,1.5)*rzN+vec3(0.1,0.8,0.9)*rxP+vec3(1.0,0.7,0.15)*rzP+vec3(0.9,0.15,0.55)*rxN+vec3(0.5,0.15,1.0)*rctr;
    float flow=fbm3(p*6.0+vec3(uTime*2.5));
    m.albedo=rC*0.12;m.metallic=0.8;m.roughness=0.02;
    m.emission=rC*(2.5+flow*2.0);
    float spark=pow(max(vnoise3(p*20.0+uTime*5.0),0.0),10.0);
    m.emission+=vec3(1.0,1.0,1.2)*spark*8.0;
  }else if(mid==18){
    // Debris — fractured concrete + thermal glow (Law of Entropy: phase change)
    float heat=SAT(uShatter*2.0-0.3);
    float grain=vnoise3(p*12.0)*0.08;
    m.albedo=vec3(0.06+grain,0.055+grain,0.05+grain);m.metallic=0.35;m.roughness=0.65+grain;
    m.emission=blackbody(mix(1200.0,3500.0,heat))*heat*4.0;
  }else{
    m.albedo=vec3(0.25,0.45,0.65);m.metallic=0.0;m.roughness=0.5;m.emission=vec3(0.15,0.45,0.9)*0.45;m.sss=1.0;
  }
  return m;
}


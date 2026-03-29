// ═══ Noise ═══
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float hash3(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float vnoise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float vnoise3(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);float n00=mix(hash3(i),hash3(i+vec3(1,0,0)),f.x);float n10=mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x);float n01=mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x);float n11=mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x);return mix(mix(n00,n10,f.y),mix(n01,n11,f.y),f.z);}
float fbm(vec2 p){float v=0.0,a=0.5;mat2 r=mat2(0.8,0.6,-0.6,0.8);for(int i=0;i<3;i++){v+=a*vnoise(p);p=r*p*2.1;a*=0.48;}return v;}
float fbm3(vec3 p){float v=0.0,a=0.5;for(int i=0;i<3;i++){v+=a*vnoise3(p);p=p*2.15+vec3(1.7,3.2,2.8);a*=0.45;}return v;}


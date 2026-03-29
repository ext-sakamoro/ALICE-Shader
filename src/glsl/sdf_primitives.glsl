// ═══ SDF Primitives ═══
float sdBox(vec3 p,vec3 b){vec3 q=abs(p)-b;return length(max(q,0.0))+min(max(q.x,max(q.y,q.z)),0.0);}
float sdRoundBox(vec3 p,vec3 b,float r){vec3 q=abs(p)-b+r;return length(max(q,0.0))+min(max(q.x,max(q.y,q.z)),0.0)-r;}
float sdSphere(vec3 p,float r){return length(p)-r;}
float sdTorus(vec3 p,vec2 t){vec2 q=vec2(length(p.xz)-t.x,p.y);return length(q)-t.y;}
float sdOctahedron(vec3 p,float s){p=abs(p);return(p.x+p.y+p.z-s)*0.57735027;}
float sdCylinder(vec3 p,float h,float r){vec2 d=abs(vec2(length(p.xz),p.y))-vec2(r,h);return min(max(d.x,d.y),0.0)+length(max(d,0.0));}
float sdGyroid(vec3 p,float sc,float th){float invSc=1.0/sc;p*=sc;return abs(dot(sin(p),cos(p.zxy)))*invSc-th;}
float smin(float a,float b,float k){float invK=1.0/k;float h=max(k-abs(a-b),0.0);return min(a,b)-h*h*0.25*invK;}
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
float disp(vec3 p){return sin(p.x*2.1+p.z*0.7)*sin(p.y*1.3+p.z*0.9)*0.5+sin(p.z*3.2-p.x*1.1)*sin(p.y*2.7)*0.25;}


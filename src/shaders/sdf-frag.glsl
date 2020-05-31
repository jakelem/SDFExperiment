#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
const float PI = 3.1415926535897932384626433832795;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.
uniform vec3 u_Resolution;

uniform float u_Time;
uniform mat4 u_ViewProj;
uniform vec3 u_CamPos;

//body, head, eye, arm, leg
uniform float u_BodySizes[6];
uniform int u_Colored[5];

//0 - 2 are upper body, 3 - 5 are lower body, 6 - 7 eyes
uniform vec3 u_BodyColors[8];
//uniform vec3 stomachColors[3];

const int numLights = 4;
const vec3 pointLights[numLights] = vec3[] (
    vec3(5,6,7), vec3(0,20,10), vec3(8,5,-7), vec3(2,0,10)
);

const float lightIntensities[numLights] = float[] (
    0.8f, 1.9f, 1.2f, 0.2f
);

const vec3 lightColors[numLights] = vec3[] (
    vec3(1,1,1), vec3(0.78, 0.9, 1.0), vec3(1,0.7,0.5), vec3(1,1,0.9)
);

const bool lightCastsShadow[numLights] = bool[] (
    true, false, true, true
);

const bool lightCastsSpecular[numLights] = bool[] (
    true, true, true, true
);

//body, eye, white
const vec3 matColors[5] = vec3[](
vec3(102, 138, 41) / 255.0,
vec3(120, 40, 35) / 255.0,
vec3(255, 255, 190) / 255.0,
vec3(40, 30, 89) / 255.0,
vec3(50, 56, 89) / 255.0);

const float matCosPow[5] = float[](
20.0, 
49.0,
8.0,
49.0,
6.0);

const float matSpec[5] = float[](
1.2, 
2.5,
0.3,
0.4,
1.2);

const float matDiff[5] = float[](
0.5, 
0.2,
0.9,
0.8,
1.0);

const vec3 bluegreen[5] = vec3[](
vec3(142, 199, 230) / 255.0,
vec3(195, 232, 213) / 255.0,
vec3(195, 232, 213) / 255.0,
vec3(195, 232, 213) / 255.0,
vec3(195, 232, 213) / 255.0);

const float cutoffs[5] = float[](0.0,0.5,0.6,0.8,0.9);

vec2 hash (vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float cubic(float t) {
    return t * t * (3.0 - 2.0 * t);
}

vec2 cubic2(vec2 t) {
    return t * t * (3.0 - 2.0 * t);
}

float quintic(float t) {
    return t * t * t * (t * (t * 6.0 + 15.0) - 10.0);
}

vec2 quintic2(vec2 t) {
    return t * t * t * (t * (t * 6.0 + 15.0) - 10.0);
}


float noise(vec2 p) {
float intX = floor(p.x);
float fractX = fract(p.x);

float intY = floor(p.y);
float fractY = fract(p.y);
fractX = cubic(fractX);
fractY = cubic(fractY);

float v1 = hash(vec2(intX,intY)).x;
float v2 = hash(vec2(intX + 1.0,intY)).x;
float v3 = hash(vec2(intX,intY + 1.0)).x;
float v4 = hash(vec2(intX + 1.0,intY + 1.0)).x;

float i1 = mix(v1, v2, fractX);
float i2 = mix(v3, v4, fractX);
return mix(i1, i2, fractY);
}

vec2 noise2(vec2 p) {
float intX = floor(p.x);
float fractX = fract(p.x);

float intY = floor(p.y);
float fractY = fract(p.y);
fractX = quintic(fractX);
fractY = quintic(fractY);

vec2 v1 = hash(vec2(intX,intY));
vec2 v2 = hash(vec2(intX + 1.0,intY));
vec2 v3 = hash(vec2(intX,intY + 1.0));
vec2 v4 = hash(vec2(intX + 1.0,intY + 1.0));

vec2 i1 = mix(v1, v2, fractX);
vec2 i2 = mix(v3, v4, fractX);
return mix(i1, i2, fractY);
}

vec3 uvToSunset(vec2 uv) {
    if(uv.y < cutoffs[0]) {
        return bluegreen[0];
    }
    else if(uv.y < cutoffs[1]) {
        return mix(bluegreen[0], bluegreen[1], (uv.y - cutoffs[0]) / (cutoffs[1] - cutoffs[0]));
    }
    else if(uv.y < cutoffs[2]) {
        return mix(bluegreen[1], bluegreen[2], (uv.y - cutoffs[1]) / (cutoffs[2] - cutoffs[1]));
    }
    else if(uv.y < cutoffs[3]) {
        return mix(bluegreen[2], bluegreen[3], (uv.y - cutoffs[2]) / (cutoffs[3] - cutoffs[2]));
    }
    else if(uv.y < cutoffs[4]) {
        return mix(bluegreen[3], bluegreen[4], (uv.y - cutoffs[3]) / (cutoffs[4] - cutoffs[3]));
    }
    return bluegreen[4];
}

vec3 transRot(vec3 p, mat4 rot, vec3 trans) {
    return (rot * vec4(p-trans, 1.0)).xyz;
}

mat4 rotateX( float angle ) {
	return mat4(	1.0,		0,			0,			0,
			 		0, 	cos(angle),	-sin(angle),		0,
					0, 	sin(angle),	 cos(angle),		0,
					0, 			0,			  0, 		1);
}

mat4 rotateY( float angle ) {
	return mat4(	cos(angle),		0,		sin(angle),	0,
			 				0,		1.0,			 0,	0,
					-sin(angle),	0,		cos(angle),	0,
							0, 		0,				0,	1);
}

mat4 rotateZ( float angle ) {
	return mat4(	cos(angle),		-sin(angle),	0,	0,
			 		sin(angle),		cos(angle),		0,	0,
							0,				0,		1,	0,
							0,				0,		0,	1);
}




vec3 uvToA(vec2 uv) {
    if(uv.y < cutoffs[0]) {
        return matColors[0];
    }
    else if(uv.y < cutoffs[1]) {
        return mix(matColors[0], matColors[1], (uv.y - cutoffs[0]) / (cutoffs[1] - cutoffs[0]));
    }
    else if(uv.y < cutoffs[2]) {
        return mix(matColors[1], matColors[2], (uv.y - cutoffs[1]) / (cutoffs[2] - cutoffs[1]));
    }
    else if(uv.y < cutoffs[3]) {
        return mix(matColors[2], matColors[3], (uv.y - cutoffs[2]) / (cutoffs[3] - cutoffs[2]));
    }
    else if(uv.y < cutoffs[4]) {
        return mix(matColors[3], matColors[4], (uv.y - cutoffs[3]) / (cutoffs[4] - cutoffs[3]));
    }
    return matColors[4];
}

vec3 twist(vec3 p) {
    float k = 1.2f; // or some other amount
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*vec2(p.x, p.z),p.y);
    return q;
}
//sdfs from Inigo Quilez https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sphere(vec3 p, float s) {
    return length(p) - s;
}

float plane(vec3 p) {
    return p.y;
}

float box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);

}

float stick(vec3 p, vec3 a, vec3 b, float r1, float r2)
{
    vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return  length( pa - ba*h ) - mix(r1,r2,h*h*(3.0-2.0*h));
}

float roundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}


float surflet(vec2 p, vec2 gridPoint) {
    vec2 t = vec2(1.0) - cubic2(abs(p - gridPoint));
    vec2 gradient = hash(gridPoint) * 2.0 - vec2(1,1);
    vec2 diff = p - gridPoint;
    float height = dot(diff, gradient);
    return height * t.x * t.y;

}

float perlin(vec2 p) {
    vec2 f = floor(p);
    return surflet(p, f+vec2(0,0)) 
    + surflet(p, f+vec2(1,0))
    + surflet(p, f+vec2(0,1))
    + surflet(p, f+vec2(1,1));
}

vec2 fbm(vec3 p, float persistence, float octaves) {
    //vec2 res = vec2(0);
    float timefactor = abs((sin(u_Time * 0.01) + 3.0) * 0.25f);
    vec2 inp = p.xy;
    float res = 0.0;
    for(float i = 0.0; i < octaves; i++) {
        res += pow(2.0, -i) * perlin(pow(persistence, i) * inp);
    }
    return vec2(res);
}


vec3 getMatColor(vec3 q, int i) {
    if(i == 0) {
        vec2 uv = q.xy * q.z - 0.04;
        uv.x *= 2.0;
        float bodtex = u_BodySizes[4];
        float n = 3.0 * perlin(bodtex * uv);
        float off = clamp(n * 5.0 * n, 0.0, 1.0);
        //vec3 f = vec3(0.5, 0.6, 0.15);
        vec3 a = u_BodyColors[0] / 255.0;
        vec3 b = u_BodyColors[1] / 255.0;
        vec3 c = u_BodyColors[2] / 255.0;
        vec3 d = u_BodyColors[3] / 255.0;

        vec3 res1 = mix(a, b, off);
        float beltex = u_BodySizes[5];

        float n2 = 5.0 * perlin(beltex * uv);
        float off2 = 1.0f - clamp(n2 * n2, 0.0, 1.0);
        vec3 res2 =  mix(c, d, off2);
        //res2 = mix(res2, c + vec3(0.1,0.1,0), clamp(1.0 - abs(q.y), 0.0, 1.0));
        //belly
        float lerpy = sphere(q -  vec3(0.0,-2.4f,2.9f),3.2f) + 1.5 * pow(q.x * 0.6, 2.0) - 0.5;
       //yellow graident
       res1 = mix(res1, b + vec3(0.37, 0.3, 0.1), 1.0 - smoothstep(-0.8, 1.0, lerpy));

        vec3 res = mix(res2, res1, smoothstep(-0.8, 0.0, lerpy));
        //lerpy = smoothstep(-0.1, 0.01, -0.1 * q.x * q.x + 0.5);

        
        //res = mix(res, res1, lerpy);

        return res;
    }
    else if(i == 2) {
        vec2 uv = q.xy * q.z;
        uv.x *= 2.0;
        float n = 5.0 * perlin(2.0 * uv);
        float off = 1.0f - clamp(n * n, 0.0, 1.0);
        vec3 res =  mix(vec3(1, 1, 0.7), vec3(0.8, 0.8, 0.5), off);
        res = mix(res, vec3(0.7, 0.6, 0.4), clamp(1.0 - abs(q.y), 0.0, 1.0));
        return res;
    }
    else if(i == 4) {
        vec3 a = u_BodyColors[4] / 255.0;
        vec2 uv = q.xy * q.z;
        uv.x *= 2.0;
        float n = 8.0 * perlin(10.0 * uv);
        float off = 1.0f - clamp(n, 0.0, 1.0);
        //return mix(vec3(0.3, 0.25, 0.05), vec3(0.4, 0.3, 0.2), off);
        return mix(a  - vec3(0.05, 0.05, 0.05), a, off);

    } else {
        return matColors[i];
    }
}


vec3 getMatDisp(vec3 q, int i) {
    if(i == 0) {
        vec2 uv = q.xy;
        float off = -0.001 * clamp(3.0 * perlin(50.0 * uv), 0.0, 1.0);
        return vec3(off);

    } else if (i == 2) {
        vec2 uv = q.xy;
        float off = -0.003 * clamp(4.0 *  perlin(38.0 * uv), 0.0, 1.0);
        return vec3(off);
    }
    else if ( i == 4) {
        vec2 uv = q.xy * q.z;
        uv.x *= 2.0;
        float n = 4.0 * perlin(10.0 * uv);
        float off = -0.001 * clamp(n * n, 0.0, 1.0);
        return vec3(off);
    } else {
        return vec3(0.0);
    }
}

float displace(vec3 p, float freq, float octaves) {
    //return sin(5.0 * sin(20.0 * p.x) + sin(20*p.y) + sin(20*p.z));
    float res = 0.0;
    float expV =2.0;
    octaves = 3.0;
    float timefactor = abs((sin(u_Time * 0.01) + 3.0) * 0.25f);
    for(float i = 0.0; i <= octaves; i++) {
        float amp = pow(2.0, -i);
        res += amp * sin(freq * pow(expV, i) * p.x +timefactor)
        + amp * sin(freq * pow(expV, i) * p.y + timefactor) +
        amp * sin(freq * pow(expV, i) * p.z + timefactor);
    }
    return res;

    /*
    return sin(3.0* p.x) + sin(3.0*p.y) + sin(3.0*p.z) +
            0.5f * (sin(6.0 * p.x) + sin(6.0 * p.y) + sin(6.0 * p.z))
            + 0.25f * (sin(12.0 * p.x) + sin(12.0 * p.y) + sin(12.0 * p.z))
            +0.125f * (sin(24.0 * p.x) + sin(24.0 * p.y) + sin(24.0 * p.z));*/
}

vec2 unionCSG(vec2 d1, vec2 d2) {
    if (d1.x > d2.x)  {
        return d2;
    }
    else{
        return d1;
    }
}

//preserves the geometry of d1, but changes color to d2
vec2 unionColor(vec2 d1, vec2 d2) {
    if (d1.x > d2.x)  {
        return vec2(d1.x, d2.y);
    }
    else{
        return d1;
    }
}

vec2 intersectionCSG(vec2 d1, vec2 d2) {
    if (d1.x < d2.x)  {
        return d2;
    }
    else{
        return d1;
    }
}

vec2 differenceCSG(vec2 d1, vec2 d2) {
    if (-d1.x < d2.x)  {
        return d2;
    }
    else{
        return vec2(-d1.x,d1.y);
    }
}

vec2 lightVis(vec3 p) {
    vec2 res = vec2(9e10, 0.0);
    for (int i = 0; i < numLights; i++) {
        vec3 transP = p - pointLights[i];
        vec2 sphere1 = vec2(sphere(transP,0.5f),0.0);
        res = unionCSG(res, sphere1);
    }
    return res;
}

vec2 smin( vec2 a, vec2 b, float k )
{
    float h = clamp( 0.5+0.5*(b.x-a.x)/k, 0.0, 1.0 );
    if(h < 0.5) {
        return vec2(mix( b.x, a.x, h ) - k*h*(1.0-h), b.y);
    } else {
        return vec2(mix( b.x, a.x, h ) - k*h*(1.0-h), a.y);
    }
}
//taken from http://iquilezles.org/www/articles/smin/smin.htm
//intersect
vec2 smax( vec2 a, vec2 b, float k )
{
    float h = max(k-abs(a.x-b.x),0.0);
    return (a.x > b.x ? vec2((a.x + h*h*0.25/k), a.y) : vec2((b.x + h*h*0.25/k), b.y));
}

vec2 scene(vec3 p) {
    if(abs(p.x) > 40.0 || abs(p.z) > 40.0 || abs(p.y) < -40.0) {
        return vec2(9e10, 0.0);
    }
    float throatsize = 0.5 * abs(sin(u_Time * 0.4));
    vec3 q = p; 
    float bs = u_BodySizes[0];
    float hs = u_BodySizes[1];
    //hs = 1.3;
    vec3 bodOffset = vec3(0,-0.1,0.9) + vec3(0, throatsize * 0.2, throatsize * 0.5);
    vec2 body = vec2(sphere(p - bodOffset, bs - 0.2 * throatsize),0.0);
    bodOffset = vec3(0,0.3,3) + vec3(0, throatsize * 0.1, throatsize * 0.1);
    vec2 head = vec2(sphere(p - bodOffset,hs),0.0);

    //mouth 
    {
        vec2 m = p.yz + vec2(-0.21, -7.1);

        float a = 0.8;
        float offZ = 0.03 * sin(15.0 * m.x + 4.6 * m.y) 
        * smoothstep(0.01, 0.06,-m.x * m.x + 0.04) * 
        smoothstep(-5.0, 10.0, -m.y * m.y + 20.0);
        head.x += offZ;
    }

    vec2 smoothy = smin(body, head, 0.4f);
    
    vec2 tail = vec2(stick(p,vec3(0,0,-1.3), vec3(0,0,-0.5), 0.45f, 0.6f),0.0);
    
    //wrinkles 
    {
        vec2 m = p.xz + vec2(0.0, -0.1);
        float offZ = 0.019 * cos(8.2 * p.x);
        smoothy.x += offZ;
    }
    vec3 rot = (rotateX(5.0) * vec4(p - vec3(0,0.3,3.8),1)).xyz;
    vec2 snout = vec2(roundBox(rot,vec3(0.2,0.2,0.2), 0.4f),0.0);
    smoothy = smin(smoothy, tail, 1.0);
    smoothy = smin(smoothy, snout, 1.0);

   // vec2 bodColor = vec2(sphere(p -  vec3(0.0,-2.4f,2.9f),3.2f),2.0);

    //smoothy = unionColor(smoothy, bodColor);




        //eyes
        {
            float ifloat = 1.0;
            vec3 sp = vec3(abs(p.x), p.yz);
            vec3 ridge = bodOffset + vec3(0.86,hs-0.4,0.42);
            //bodOffset = vec3(0,0.3,3)

            float es = u_BodySizes[2];
            float ps = u_BodySizes[3];

            vec2 eyeridge1 = vec2(sphere(sp - ridge,es),0.0);
            smoothy = smin(smoothy, eyeridge1, 0.09f);
            //vec2 eyeposridge + (0.03, 0, 0.05);
            float esf = es / 0.45;
            ridge += vec3(0.03, 0.0, 0.05);
            vec2 eyeball1 = vec2(sphere(sp - ridge,es-0.04),1.0);
            ridge += vec3(0.015, 0, 0.025);
            vec2 sclera = vec2(sphere(sp - ridge,es-0.06),4.0);
            vec2 slitA = vec2(sphere(sp - (ridge + vec3(0.085, ps, 0.135)),es - 0.13),1.0);
            vec2 slitB = vec2(sphere(sp - (ridge + vec3(0.085, -ps, 0.135)),es - 0.13),1.0);
            vec2 slit = smax(slitA, slitB, 0.05);
            vec2 cut1 = vec2(sphere(sp - vec3(0.89,1.18,3.4),es - 0.05),1.0);

            sclera = smax(vec2(-cut1.x, cut1.y), sclera, 0.04);
            sclera = smax(vec2(-slit.x, slit.y), sclera, 0.04);

            //smoothy = smin(smoothy, slit, 0.01);
            smoothy = smin(smoothy, eyeball1, 0.01);
            smoothy = smin(smoothy, sclera, 0.02);

        }

        //arms
        {
            vec3 sp = vec3(abs(p.x), p.yz);
            vec3 shoulder = vec3(1.3,-0.3,2.5);
            vec3 elbow = shoulder + vec3(0.6,-0.7,-0.3);
            vec3 wrist = elbow + vec3(-0.5,-0.6,0.6);
            vec3 f1 = wrist + vec3(-0.8,-0.1,1.5);

            vec2 sticky = vec2(stick(sp, shoulder, elbow, 0.4f, 0.34f), 0.0);
            vec2 forearm = vec2(stick(sp, elbow, wrist, 0.3f, 0.4f), 0.0);
            wrist -= vec3(0.2,0.3,0);
            vec2 finger = vec2(stick(sp, wrist, f1, 0.2f, 0.1f), 0.0);
            vec3 w = (sp - wrist);
            //float offZ = -0.01 * (sin(w.z * 30.3) + 1.0) + wz;   
            float offZ = -0.05 * (clamp(cubic(((-length(w) + 0.7) * 3.7) * 0.15), -2.0, 3.0));         
            float sz = sin(w.z * w.z * 3.3);
            offZ += -0.01 * (sz * sz);   
            finger.x += offZ;
            //finger.x += 0.2;

            smoothy = smin(smoothy, sticky, 0.1);
            smoothy = smin(smoothy, forearm, 0.1);
           smoothy = smin(smoothy, finger, 0.2);
            f1 = wrist + vec3(-0.3,-0.1,1.7);
            finger = vec2(stick(sp, wrist, f1, 0.2f, 0.1f), 0.0);
            finger.x += offZ;

            smoothy = smin(smoothy, finger, 0.2);
            f1 = wrist + vec3(0.2,-0.1,1.6);
            finger = vec2(stick(sp, wrist, f1, 0.2f, 0.1f), 0.0);
            finger.x += offZ;

            smoothy = smin(smoothy, finger, 0.2);

        }

        //legs
        {
            vec3 sp = vec3(abs(p.x), p.yz);
            vec3 hip = vec3(1.0,-0.2,-1.3);
            vec3 knee = hip + vec3(0.4,-0.7,1.3);
            vec3 wrist = knee + vec3(-0.5,-0.7, -1.3);
            vec3 f1 = wrist + vec3(-0.3,-0.1,1.7);
            vec3 f2 = wrist + vec3(0.2,-0.1,2.2);
            vec3 f3 = wrist + vec3(1.0,-0.1,1.9);

            vec2 upleg = vec2(stick(sp, hip, knee, 0.55f, 0.42f), 0.0);
            vec2 lowleg = vec2(stick(sp, knee, wrist, 0.5f, 0.45f), 0.0);
            wrist -= vec3(0.2,0.3,0);
            vec2 finger = vec2(stick(sp, wrist, f1, 0.2f, 0.2f), 0.0);

            smoothy = smin(smoothy, upleg, 0.3);
            smoothy = smin(smoothy, lowleg, 0.1);
            smoothy = smin(smoothy, finger, 0.2);
            finger = vec2(stick(sp, wrist, f2, 0.2f, 0.2f), 0.0);
            smoothy = smin(smoothy, finger, 0.2);

            finger = vec2(stick(sp, wrist, f3, 0.2f, 0.2f), 0.0);
            smoothy = smin(smoothy, finger, 0.2);

            
        }

    vec2 throat = vec2(sphere(p - vec3(0,-0.6,3.0),1.1f + throatsize),0.0);

    smoothy = smin(smoothy, throat, 0.2f);

    vec2 plane = vec2(plane(p + vec3(0,2,0)),3.0);
    vec3 off = getMatDisp(p, int(smoothy.y));
    smoothy.x += off.x;
    vec2 res = vec2(smoothy.x * 0.9, smoothy.y);

    return res;


}

vec2 sceneA(vec3 p) {
    if(abs(p.x) > 40.0 || abs(p.z) > 40.0 || abs(p.y) < -40.0) {
        return vec2(9e10, 0.0);
    }
    vec3 twisted = twist(p);
    float sphere2 = sphere(twisted,3.0);
    float boxy = box(twisted,vec3(2,2,2));

    vec2 box1 = vec2(box(p + vec3(0,2,0), vec3(2,4,2)), 0.0);
    vec2 box2 = vec2(box(p + vec3(0,7,0), vec3(2,4,2)), 0.0);


    vec2 normSphere = vec2(sphere(p - vec3(0,0,2), 2.0),2.0);

    vec2 twisty = vec2(sphere2 + 0.3 * displace(twisted, 2.0, 2.0), 1.0);
    vec2 plane = vec2(plane(p + vec3(0,5,0)),3.0);
    p.x += 4.0;
    p.y += -3.0;

    float s3 = sphere(p, 1.5f);
    vec2 sphere3 = vec2(s3,2.0);

    vec2 world = differenceCSG(normSphere, twisty);
    //world = differenceCSG(sphere3, world);
    vec2 cutout = differenceCSG(normSphere, box1);

    // world = twisty;

    vec2 res = world;//unionCSG(world, plane);
    res = unionCSG(res, box2);
    res.x *= 0.2;
    return res;
}


float epsilon = 0.001;
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(scene(vec3(p.x + epsilon, p.y, p.z)).x - scene(vec3(p.x - epsilon, p.y, p.z)).x,
                                   scene(vec3(p.x, p.y  + epsilon, p.z)).x - scene(vec3(p.x, p.y - epsilon, p.z)).x,
                                   scene(vec3(p.x, p.y, p.z  + epsilon)).x - scene(vec3(p.x, p.y, p.z - epsilon)).x));
}
float precis = 0.002;
vec4 raymarch(vec3 rayDir, vec3 rayOrigin)
{
    //p is the far clip position we are casting to
    float tmax = 100.0;
    float t = 0.0;
    int maxSteps = 250;
    for(int i = 0; i < maxSteps; i++) {
        vec3 p = rayOrigin + rayDir * t;
        vec2 res = (scene(p));
        //res = unionCSG(lightVis(p), scene(p));
        float dist = res.x;
        int col = int(res.y);
        if (dist <precis) {
            if(dist < 0.0) {
               return vec4(p - rayDir * dist, col);
            }
            //final term is color index
            return vec4(p,col);
        }
       // dist = clamp(dist, 0.1f,4.0);
        t += dist;
        if(t > tmax) {
            //return vec4(0.0,0.0,0.0,-1.0);
        }

    }
    return vec4(0.0,0.0,0.0,-1.0);
}

//x: light intensity, y: reflected color index, if applicable
vec2 shadow (vec3 lightDir, vec3 rayOrigin, float tmax) {
    float penumbraK = 8.0;
    float t = 0.0;
    int maxSteps = 200;
    float sol = 1.0f;
    for(int i = 0; i < maxSteps; i++) {
        vec3 p = rayOrigin + lightDir * t;
        vec2 res = scene(p);
        float dist = res.x;

        if (dist < precis) {
            return vec2(0.0f,res.y) ;
        }
        float s = clamp(penumbraK * dist / t, 0.0, 1.0);
        sol = min( sol, s);
        t += clamp(dist,0.04,0.1);
        if(t > tmax) {
            break;
        }
    }
    return vec2(sol,-1.0);
}

vec3 squareToHemisphere(vec2 s) {
    float z = s.x;
    float x = cos(2.0 * PI * s.y) * sqrt(1.0 - z * z);
    float y = sin(2.0 * PI * s.y) * sqrt(1.0 - z * z);
    return vec3(x,y,z);
}


float ao(vec3 p, vec3 nor) {
    int numSteps = 5;
    float intensity = 0.6f;
    float decay = 0.5f;
    //larger res means more occlusion
    float res = 0.0;
    vec3 tangent = normalize(cross(vec3(0,1,0),nor));
    vec3 bitangent = normalize(cross(nor, tangent));
    mat4 trans = mat4(vec4(tangent,0), vec4(bitangent, 0), vec4(nor,0), vec4(0,0,0,1));
    for(int i = 0; i < numSteps; i++) {
        for(int j = 0; j < numSteps; j++) {
            vec2 s = vec2(i,j);
            vec4 pos = trans * vec4(squareToHemisphere(s),1);
            //vec3 pos = p + sHem.xyz;
            vec3 rayDir = normalize(pos.xyz);
            rayDir *= sign(dot(rayDir, nor));
            //t is distance from current object
            float radius = 0.01;

            float dist = scene(p + nor * 0.04 + rayDir * radius).x;
            res += max((dist + 0.001)* 100.0,0.0);
            
            vec3 offP = p + nor * 0.01 + rayDir * radius;
        }
    }
    res /= 25.0;
    res = 1.0;
    return clamp(res * res, 0.0f, 1.0f);

}

vec3 renderDiff(vec4 isect) {
    return getMatColor(isect.xyz, int(isect.w));
    
}

vec4 render(vec4 isect) {

    vec3 nor = estimateNormal(isect.xyz);

    if(u_Colored[2] == 1) {
        return vec4(nor.xyz,1.0);
    }
    vec3 res = vec3(0.0);
    vec3 test = vec3(0.0);
    int geom = int(isect.w);
    vec3 albedo = getMatColor(isect.xyz, geom);

    if(u_Colored[0] == 0) {
        return vec4(albedo.xyz,1.0);
    }

    float kd = matDiff[geom];
    float ks = matSpec[geom];
    vec3 ref = reflect( normalize(isect.xyz - u_CamPos.xyz), nor );

    { // skylight
        vec3 lightOrigin = vec3(0,20,10);
        vec3 lightCol = vec3(0.78, 0.9, 1.0);
        vec3 lightDir = normalize(lightOrigin-isect.xyz);
        float lightDist = length(lightOrigin-isect.xyz) * 0.1f;
        float lightIntensity = 2.0 / lightDist;
        float ambientTerm = 1.0;// ao(isect.xyz,nor);
        vec2 lighting = vec2(1.0,1.0);
        if(u_Colored[1] == 1) {
            lighting = shadow(lightDir,isect.xyz + nor * 0.03f, lightDist);
        }
        
        vec3 h = normalize(isect.xyz - u_CamPos - lightDir);
        float specularIntensity = max(pow(dot(h, nor), matCosPow[geom]), 0.0);
        vec3 refCol = vec3(1.0); 

        if(u_Colored[1] == 1) {
            vec2 reflected = shadow(ref, isect.xyz + nor * 0.03f, 2.5f);
            if(reflected.y > -0.5f) {
                refCol = matColors[int(reflected.y)];
            }
            specularIntensity *= reflected.x;
        }

        float diffuseTerm = dot(normalize(nor), normalize(lightOrigin));
        diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
        
        res += kd * ((lightCol * lightIntensity  * lighting.x * diffuseTerm) * albedo);
        res +=  ks * lightCol * lightIntensity * specularIntensity * refCol;
    
    }  
    return vec4(res.xyz,1.0);
}


vec4 renderA(vec4 isect) {

    vec3 nor = estimateNormal(isect.xyz);
    vec3 res = vec3(0.0);
    vec3 test = vec3(0.0);
    int geom = int(isect.w);
    vec3 albedo = getMatColor(isect.xyz, geom);
    float kd = matDiff[geom];
    float ks = matSpec[geom];

    for(int i = 0; i < numLights; i ++) {
        vec3 ref = reflect( normalize(isect.xyz - u_CamPos.xyz), nor );

        vec3 lightOrigin = pointLights[i];
        vec3 lightCol = lightColors[i];
        vec3 lightDir = normalize(lightOrigin-isect.xyz);
        float lightDist = length(lightOrigin-isect.xyz) * 0.1f;

        float lightIntensity = lightIntensities[i] / lightDist;
        test = lightDir;
        float ambientTerm =1.0;// ao(isect.xyz,nor);
        vec2 lighting = vec2(1.0,1.0);

        if(lightCastsShadow[i] && u_Colored[1] == 1) {
            lighting = shadow(lightDir,isect.xyz + nor * 0.03f, lightDist);
        }
         
        float intensity = lighting.x;
        
        vec3 h = (normalize(isect.xyz - u_CamPos) - lightDir) * 0.5f;
        float specularIntensity = max(pow(dot(h, nor), matCosPow[geom]), 0.0);
        vec3 refCol = vec3(1.0); 

        if(u_Colored[1] == 1) {
            vec2 reflected = shadow(ref, isect.xyz + nor * 0.03f, 2.5f);

            if(reflected.y > -0.5f) {
                refCol = matColors[int(reflected.y)];
            }

            specularIntensity *= reflected.x;
        }

        float diffuseTerm = 1.0 - dot(normalize(vec4(nor,1)), normalize(vec4(-lightDir,1)));
        diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
        res += kd * ((lightCol * lightIntensity  * intensity * diffuseTerm) * albedo);

        if(lightCastsSpecular[i]) {
            res +=  ks * lightCol * lightIntensity * specularIntensity * refCol;
        }
       // res = nor;
       // res = albedo;

    }
    return vec4(res.xyz,1.0);
}




void main()
{
    vec2 ndc = (gl_FragCoord.xy / u_Resolution.xy) * 2.0 - 1.0; // -1 to 1 NDC
    //vec2 ndc = (vec2(1) + fs_Pos.xy) *0.5f;
    //ndc.y = 1.0 - ndc.y;
    //ndc = vec2(1,1);
    //    outColor = vec3(ndc * 0.5 + 0.5, 1);
    vec3 blankCol = uvToSunset(ndc);
    vec4 p = vec4(ndc.xy, 1, 1); // Pixel at the far clip plane
    p *= 1000.0; // Times far clip plane value
    p = u_ViewProj  * p; // Convert from unhomogenized screen to world

    //determine the ray between the camera and the viewing frustum at the specific pixel
    //because it is normalized, we are essentially projecting a circle of radius 1 against the plane
    vec3 rayDir = normalize(p.xyz - u_CamPos);

    vec3 p1 = u_CamPos;
    
    vec4 isect = raymarch(rayDir,u_CamPos);
    if(isect.w > -0.5f) {
        
        //diffuseTerm += specularIntensity;
        vec3 col = vec3(0);
        col = render(isect).xyz;
        
         
        //float fogLerp = clamp(length(isect.xz) / 30.0 - 0.5,0.0,1.0);
        //col = mix(col.xyz, blankCol.xyz, fogLerp);
        out_Col = vec4(col,1);

    } else {
        out_Col = vec4(blankCol, 1);
       // out_Col = vec4(p.xyz * 0.001f, 1);

    }
}

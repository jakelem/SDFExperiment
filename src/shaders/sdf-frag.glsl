#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
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

const int numLights = 4;
const vec3 pointLights[numLights] = vec3[] (
    vec3(5,6,7), vec3(0,10,10), vec3(8,5,-7), vec3(14,20,10)
);

const float lightIntensities[numLights] = float[] (
    0.8f, 1.6f, 1.2f, 0.f
);

const vec3 lightColors[numLights] = vec3[] (
    vec3(1,1,1), vec3(0.3, 0.4, 1.0), vec3(1,0.7,0.5), vec3(1,1,0.9)
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
vec3(20, 10, 10) / 255.0,
vec3(255, 255, 190) / 255.0,
vec3(40, 30, 89) / 255.0,
vec3(50, 56, 89) / 255.0);

const float matCosPow[5] = float[](
150.0, 
6.0,
980.0,
6.0,
6.0);

const float matSpec[5] = float[](
0.3, 
1.7,
0.3,
0.2,
0.6);

const float matDiff[5] = float[](
1.0, 
1.0,
0.9,
0.4,
0.1);

const vec3 bluegreen[5] = vec3[](
vec3(142, 199, 230) / 255.0,
vec3(195, 232, 213) / 255.0,
vec3(195, 232, 213) / 255.0,
vec3(195, 232, 213) / 255.0,
vec3(195, 232, 213) / 255.0);

const float cutoffs[5] = float[](0.0,0.5,0.6,0.8,0.9);


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
    return (rot * vec4(p-trans, 1.f)).xyz;
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

float displace(vec3 p, float freq, float octaves) {
    //return sin(5.f * sin(20.f * p.x) + sin(20*p.y) + sin(20*p.z));
    
    float res = 0.f;
    float expV =2.f;
    octaves = 3.f;
    float timefactor = abs((sin(u_Time * 0.01) + 3.f) * 0.25f);
    for(float i = 0.f; i <= octaves; i++) {
        float amp = pow(2.f, -i);
        res += amp * sin(freq * pow(expV, i) * p.x +timefactor)
        + amp * sin(freq * pow(expV, i) * p.y + timefactor) +
        amp * sin(freq * pow(expV, i) * p.z + timefactor);
    }
    return res;

    /*
    return sin(3.f* p.x) + sin(3.f*p.y) + sin(3.f*p.z) +
            0.5f * (sin(6.f * p.x) + sin(6.f * p.y) + sin(6.f * p.z))
            + 0.25f * (sin(12.f * p.x) + sin(12.f * p.y) + sin(12.f * p.z))
            +0.125f * (sin(24.f * p.x) + sin(24.f * p.y) + sin(24.f * p.z));*/
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
    vec2 res = vec2(9e10, 0.f);
    for (int i = 0; i < numLights; i++) {
        vec3 transP = p - pointLights[i];
        vec2 sphere1 = vec2(sphere(transP,0.5f),0.f);
        res = unionCSG(res, sphere1);
    }
    return res;
}

vec2 smin( vec2 a, vec2 b, float k )
{
    float h = clamp( 0.5+0.5*(b.x-a.x)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
//taken from http://iquilezles.org/www/articles/smin/smin.htm
//intersect
vec2 smax( vec2 a, vec2 b, float k )
{
    float h = max(k-abs(a.x-b.x),0.0);
    return (a.x > b.x ? vec2((a.x + h*h*0.25/k), a.y) : vec2((b.x + h*h*0.25/k), b.y));
}

vec2 scene(vec3 p) {
    if(abs(p.x) > 40.f || abs(p.z) > 40.f || abs(p.y) < -40.f) {
        return vec2(9e10, 0.f);
    }
    float throatsize = 0.4 * abs(sin(u_Time * 0.1));
    vec2 body = vec2(sphere(p - vec3(0,-0.1,0.9),1.9f),0.f);
    vec2 head = vec2(sphere(p - vec3(0,0.3,3),1.3f),0.f);

    vec2 smoothy = smin(body, head, 0.4f);

    vec2 throat = vec2(sphere(p - vec3(0,-0.7,2.7),1.1f + throatsize),0.f);
    vec2 box = vec2(roundBox(p - vec3(0,0,-1),vec3(0.3,0.3,0.3), 0.3f),0.f);
    vec3 rot = (rotateX(5.f) * vec4(p - vec3(0,0.3,3.8),1)).xyz;
    vec2 snout = vec2(roundBox(rot,vec3(0.2,0.2,0.2), 0.4f),0.f);

    smoothy = smin(smoothy, throat, 0.5f);
    smoothy = smin(smoothy, box, 1.f);
    smoothy = smin(smoothy, snout, 1.f);

    vec2 bodColor = vec2(sphere(p -  vec3(0.f,-2.4f,2.9f),3.2f),2.f);

    smoothy = unionColor(smoothy, bodColor);

        //eyes
        {
            float ifloat = 1.f;
            vec3 sp = vec3(abs(p.x), p.yz);
            vec2 eyeridge1 = vec2(sphere(sp - vec3(0.9,1.2,3.42),0.45f),0.f);
            smoothy = smin(smoothy, eyeridge1, 0.09f);

            vec2 eye1 = vec2(sphere(sp - vec3(0.9 * ifloat,1.2,3.4),0.45f),1.f);
            vec2 eyeball1 = vec2(sphere(sp - vec3(0.95 * ifloat,1.2,3.5),0.4f),1.f);
            vec2 sclera = vec2(sphere(sp - vec3(0.95 * ifloat,1.2,3.5),0.42f),2.f);
            vec2 slitA = vec2(sphere(sp - vec3(1.0 * ifloat,1.32,3.64),0.33f),2.f);
            vec2 slitB = vec2(sphere(sp - vec3(1.0 * ifloat,1.12,3.64),0.33f),2.f);
            vec2 slit = intersectionCSG(slitA, slitB);
            vec2 cut1 = vec2(sphere(sp - vec3(0.89 * ifloat,1.18,3.4),0.4f),2.f);

            eyeball1 = smax(slit, eyeball1, 0.02);
            sclera = smax(vec2(-cut1.x, cut1.y), sclera, 0.04);
            //smoothy = unionCSG(smoothy, slit1);

            smoothy = smin(smoothy, eyeball1, 0.01);
            smoothy = smin(smoothy, sclera, 0.02);

        }

        //arms
        {
            vec3 sp = vec3(abs(p.x), p.yz);
            vec3 shoulder = vec3(1.3,-0.3,2.5);
            vec3 elbow = shoulder + vec3(0.5,-0.7,-0.3);
            vec3 wrist = elbow + vec3(-0.5,-0.6,0.6);
            vec3 f1 = wrist + vec3(-0.8,-0.1,1.1);
            vec3 f2 = wrist + vec3(-0.3,-0.1,1.6);
            vec3 f3 = wrist + vec3(0.2,-0.1,1.3);

            vec2 sticky = vec2(stick(sp, shoulder, elbow, 0.4f, 0.34f), 0.f);
            vec2 forearm = vec2(stick(sp, elbow, wrist, 0.3f, 0.4f), 0.f);
            wrist -= vec3(0.2,0.3,0);
            vec2 finger = vec2(stick(sp, wrist, f1, 0.2f, 0.2f), 0.f);

            smoothy = smin(smoothy, sticky, 0.3);
            smoothy = smin(smoothy, forearm, 0.1);
            smoothy = smin(smoothy, finger, 0.2);
            finger = vec2(stick(sp, wrist, f2, 0.2f, 0.2f), 0.f);
            smoothy = smin(smoothy, finger, 0.2);

            finger = vec2(stick(sp, wrist, f3, 0.2f, 0.2f), 0.f);
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

            vec2 upleg = vec2(stick(sp, hip, knee, 0.55f, 0.42f), 0.f);
            vec2 lowleg = vec2(stick(sp, knee, wrist, 0.5f, 0.45f), 0.f);
            wrist -= vec3(0.2,0.3,0);
            vec2 finger = vec2(stick(sp, wrist, f1, 0.2f, 0.2f), 0.f);

            smoothy = smin(smoothy, upleg, 0.3);
            smoothy = smin(smoothy, lowleg, 0.1);
            smoothy = smin(smoothy, finger, 0.2);
            finger = vec2(stick(sp, wrist, f2, 0.2f, 0.2f), 0.f);
            smoothy = smin(smoothy, finger, 0.2);

            finger = vec2(stick(sp, wrist, f3, 0.2f, 0.2f), 0.f);
            smoothy = smin(smoothy, finger, 0.2);

        }

    
    vec2 snowman = unionCSG(head, body);
    snowman = unionCSG(snowman, throat);

    vec2 plane = vec2(plane(p + vec3(0,2,0)),3.f);
  // vec2 res = unionCSG(snowman, plane);
    vec2 res = vec2(smoothy.x * 0.6, smoothy.y);
    return res;


}

vec2 sceneA(vec3 p) {
    if(abs(p.x) > 40.f || abs(p.z) > 40.f || abs(p.y) < -40.f) {
        return vec2(9e10, 0.f);
    }
    vec3 twisted = twist(p);
    float sphere2 = sphere(twisted,3.f);
    float boxy = box(twisted,vec3(2,2,2));

    vec2 box1 = vec2(box(p + vec3(0,2,0), vec3(2,4,2)), 0.f);
    vec2 box2 = vec2(box(p + vec3(0,7,0), vec3(2,4,2)), 0.f);


    vec2 normSphere = vec2(sphere(p - vec3(0,0,2), 2.f),2.f);

    vec2 twisty = vec2(sphere2 + 0.3 * displace(twisted, 2.f, 2.f), 1.f);
    vec2 plane = vec2(plane(p + vec3(0,5,0)),3.f);
    p.x += 4.f;
    p.y += -3.f;

    float s3 = sphere(p, 1.5f);
    vec2 sphere3 = vec2(s3,2.f);

    vec2 world = differenceCSG(normSphere, twisty);
    //world = differenceCSG(sphere3, world);
    vec2 cutout = differenceCSG(normSphere, box1);

    // world = twisty;

    vec2 res = world;//unionCSG(world, plane);
    res = unionCSG(res, box2);
    res.x *= 0.2;
    return res;
}


float epsilon = 0.0001;
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(scene(vec3(p.x + epsilon, p.y, p.z)).x - scene(vec3(p.x - epsilon, p.y, p.z)).x,
                                   scene(vec3(p.x, p.y  + epsilon, p.z)).x - scene(vec3(p.x, p.y - epsilon, p.z)).x,
                                   scene(vec3(p.x, p.y, p.z  + epsilon)).x - scene(vec3(p.x, p.y, p.z - epsilon)).x));
}
float precis = 0.002;
vec4 raymarch(vec3 rayDir, vec3 rayOrigin)
{
    //p is the far clip position we are casting to
    float tmax = 100.f;
    float t = 0.f;
    int maxSteps = 250;
    for(int i = 0; i < maxSteps; i++) {
        vec3 p = rayOrigin + rayDir * t;
        vec2 res = (scene(p));
        //res = unionCSG(lightVis(p), scene(p));
        float dist = res.x;
        int col = int(res.y);
        if (dist <precis) {
            if(dist < 0.f) {
               return vec4(p - rayDir * dist, col);
            }
            //final term is color index
            return vec4(p,col);
        }
       // dist = clamp(dist, 0.1f,4.f);
        t += dist;
        if(t > tmax) {
            //return vec4(0.f,0.f,0.f,-1.f);
        }

    }
    return vec4(0.f,0.f,0.f,-1.f);
}

//x: light intensity, y: reflected color index, if applicable
vec2 shadow (vec3 lightDir, vec3 rayOrigin, float tmax) {
    float penumbraK = 8.f;
    float t = 0.f;
    int maxSteps = 200;
    float sol = 1.0f;
    for(int i = 0; i < maxSteps; i++) {
        vec3 p = rayOrigin + lightDir * t;
        vec2 res = scene(p);
        float dist = res.x;

        if (dist < precis) {
            return vec2(0.0f,res.y) ;
        }
        float s = clamp(penumbraK * dist / t, 0.f, 1.f);
        sol = min( sol, s);
        t += clamp(dist,0.04,0.1);
        if(t > tmax) {
            break;
        }
    }
    return vec2(sol,-1.f);
}

vec3 squareToHemisphere(vec2 s) {
    float z = s.x;
    float x = cos(2.f * PI * s.y) * sqrt(1.f - z * z);
    float y = sin(2.f * PI * s.y) * sqrt(1.f - z * z);
    return vec3(x,y,z);
}
float ao(vec3 p, vec3 nor) {
    int numSteps = 5;
    float intensity = 0.6f;
    float decay = 0.5f;
    //larger res means more occlusion
    float res = 0.f;
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
            //farther away, less ao
            //float dist = scene(offP).x;
            //if (dist < 0.0) break;
            //if(t - dist)
            //res += intensity * (t - dist);
            //intensity *= decay;
            //if(res > 0.1) break;
        }
    }
    res /= 25.f;
    res = 1.f;
    return clamp(res * res, 0.0f, 1.0f);

}
vec4 render(vec4 isect) {

    vec3 nor = estimateNormal(isect.xyz);
    vec3 res = vec3(0.f);
    vec3 test = vec3(0.f);
    for(int i = 0; i < numLights; i ++) {
        vec3 ref = reflect( normalize(isect.xyz - u_CamPos.xyz), nor );

        vec3 lightOrigin = pointLights[i];
        vec3 lightCol = lightColors[i];

        vec3 lightDir = normalize(lightOrigin-isect.xyz);
        float lightDist = length(lightOrigin-isect.xyz) * 0.1f;

        float lightIntensity = lightIntensities[i] / lightDist;
        test = lightDir;
        float ambientTerm =1.f;// ao(isect.xyz,nor);
        vec2 lighting = vec2(1.f,1.f);

        if(lightCastsShadow[i]) {
            lighting = shadow(lightDir,isect.xyz + nor * 0.03f, lightDist);
        }
         
        float intensity = lighting.x;
        int geom = int(isect.w);
        //material values
        vec3 albedo = matColors[geom];
        float kd = matDiff[geom];
        float ks = matSpec[geom];

        vec3 h = (normalize(isect.xyz - u_CamPos) - lightDir) * 0.5f;
        float specularIntensity = max(pow(dot(h, nor), matCosPow[i]), 0.f);
        vec2 reflected = shadow(ref, isect.xyz + nor * 0.03f, 2.5f);
        vec3 refCol = vec3(1.f); 

        if(reflected.y > -0.5f) {
            refCol = matColors[int(reflected.y)];
        }

        specularIntensity *= reflected.x;

        //specularIntensity = 1.f;
        float diffuseTerm = 1.f - dot(normalize(vec4(nor,1)), normalize(vec4(-lightDir,1)));
        //diffuseTerm *= ambientTerm;
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);
        res += kd * ((lightCol * lightIntensity  * intensity * diffuseTerm) * albedo);
        if(lightCastsSpecular[i]) {
            res +=  ks * lightCol * lightIntensity * specularIntensity * refCol;
        }
       // res = nor;
       // res = albedo;

    }

    return vec4(res.xyz,1.f);
    
}



void main()
{
    vec2 ndc = (gl_FragCoord.xy / u_Resolution.xy) * 2.0 - 1.0; // -1 to 1 NDC
    //vec2 ndc = (vec2(1) + fs_Pos.xy) *0.5f;
    //ndc.y = 1.f - ndc.y;
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
        vec3 col = render(isect).xyz;
        //float fogLerp = clamp(length(isect.xz) / 30.f - 0.5,0.f,1.f);
        //col = mix(col.xyz, blankCol.xyz, fogLerp);
        out_Col = vec4(col,1);

    } else {
        out_Col = vec4(blankCol, 1);
       // out_Col = vec4(p.xyz * 0.001f, 1);

    }
   // out_Col = vec4(rayDir,1);
    // Material base color (before shading)
        vec4 diffuseColor = fs_Col;
        
         //diffuseColor = vec4(0.1,1,1,1);
        // Calculate the diffuse term for Lambert shading
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        //float ambientTerm = 0.7;

       // float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
//                                                            //lit by our point light are not completely black.
//        if(lightIntensity == 0f) {
//            lightIntensity = 0.2f;
//        }
        // Compute final shaded color
}

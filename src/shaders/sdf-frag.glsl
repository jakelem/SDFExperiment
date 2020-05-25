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

const int numLights = 2;
const vec3 pointLights[numLights] = vec3[] (
    vec3(2,4,3), vec3(-2,4,3)
);


const vec3 geomColors[5] = vec3[](
vec3(23, 59, 132) / 255.0,
vec3(131, 23, 73) / 255.0,
vec3(40, 80, 109) / 255.0,
vec3(195, 232, 213) / 255.0,
vec3(195, 232, 213) / 255.0);

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

vec3 twist(vec3 p) {
    float k = 1.3f; // or some other amount
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*vec2(p.x, p.z),p.y);
    return q;
}

float sphere(vec3 p, float s) {
    return length(p) - s;
}

float plane(vec3 p) {
    return p.y;
}

float displace(vec3 p, float freq, float octaves) {
    //return sin(5.f * sin(20.f * p.x) + sin(20*p.y) + sin(20*p.z));
    float res = 0.f;
    for(float i = 0.f; i <= octaves; i++) {
        float amp = pow(2.f, -i) * ((sin(u_Time * 0.01) + 2.f) * 0.25f);
        res += amp * sin(freq * pow(2.f, i) * p.x)
        + amp * sin(freq * pow(2.f, i) * p.y) +
        amp * sin(freq * pow(2.f, i) * p.z);
    }
    return res;
  //  return sin(3.f* p.x) + sin(3.f*p.y) + sin(3.f*p.z) +
            //0.5f * (sin(6.f * p.x) + sin(6.f * p.y) + sin(6.f * p.z))
            //+ 0.25f * (sin(12.f * p.x) + sin(12.f * p.y) + sin(12.f * p.z))
            //+0.125f * (sin(24.f * p.x) + sin(24.f * p.y) + sin(24.f * p.z));
}

vec2 unionCSG(vec2 d1, vec2 d2) {
    if (d1.x > d2.x)  {
        return d2;
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

vec2 scene(vec3 p) {
    vec3 twisted = twist(p);
    float sphere2 = sphere(twisted,3.f);

    p.x += -2.f;

    vec2 normSphere = vec2(sphere(p, 3.f),0.f);


    vec2 twisty = vec2(sphere2 + displace(twisted, 2.f, 3.f), 1.f);
    vec2 plane = vec2(plane(p + vec3(0,4,0)),2.f);

    p.x += 4.f;
    p.y += -3.f;

    float s3 = sphere(p, 1.5f) + displace(p,3.f,3.f);
    vec2 sphere3 = vec2(s3,2.f);

    vec2 world = differenceCSG(normSphere, twisty);
    world = differenceCSG(sphere3, world);
    vec2 res = unionCSG(world, plane);
    //res = unionCSG(res, sphere3);

    return res;
}


float epsilon = 0.01;
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(scene(vec3(p.x + epsilon, p.y, p.z)).x - scene(vec3(p.x - epsilon, p.y, p.z)).x,
                                   scene(vec3(p.x, p.y  + epsilon, p.z)).x - scene(vec3(p.x, p.y - epsilon, p.z)).x,
                                   scene(vec3(p.x, p.y, p.z  + epsilon)).x - scene(vec3(p.x, p.y, p.z - epsilon)).x));
}

vec4 raymarch(vec3 rayDir, vec3 rayOrigin)
{
    //p is the far clip position we are casting to
    float tmax = 80.f;
    float t = 0.f;
    int maxSteps = 300;
    for(int i = 0; i < maxSteps; i++) {
        vec3 p = rayOrigin + rayDir * t;
        vec2 res = scene(p);
        float dist = res.x;
        int col = int(res.y);
        if (dist < 0.001f) {
            if(dist < 0.f) {
               // return vec4(p - rayDir * dist, 1);
            }
            //final term is color index
            return vec4(p,col);
        }

        t += dist;
        if(t > 1000.f) {
            return vec4(0.f,0.f,0.f,-1.f);
        }

    }
    return vec4(0.f,0.f,0.f,-1.f);
}

//x: light intensity, yzw: reflected color index, if applicable
vec2 shadow (vec3 lightDir, vec3 rayOrigin) {
    float penumbraK = 1.0f;
    float tmax = 20.f;
    float t = 0.f;
    int maxSteps = 20;
    float res = 1.0f;
    for(int i = 0; i < maxSteps; i++) {
        vec3 p = rayOrigin + lightDir * t;
        vec2 res = scene(p);
        float dist = res.x;

        if (dist < 0.01f) {
            return vec2(0.0f,res.y) ;
        }
        res = min( res, penumbraK * dist / t );
        t += dist;
    }
    return vec2(res,-1.f);
}


float ao(vec3 p, vec3 nor) {
    int numSteps = 10;
    float intensity = 1.f;
    float decay = 0.95f;
    //larger res means more occlusion
    float res = 0.f;
    for(int i = 0; i < numSteps; i++) {
        //t is distance from current object
        float t = 0.02f * (float(i)) + 0.02;
        vec3 offP = p + nor * t;
        //farther away, less ao
        float dist = scene(offP).x;
        //if (dist < 0.0) break;
        res += intensity * (t - dist);
        intensity *= decay;
        if(res > 0.25) break;
    }
    return clamp(1.0f - 3.5f * res, 0.0f, 1.0f);

}
vec4 render(vec4 isect) {

    vec3 nor = estimateNormal(isect.xyz);
    vec3 res = vec3(0.f);
    for(int i = 0; i < numLights; i ++) {
        vec3 lightOrigin = pointLights[i];
        vec3 lightDir = isect.xyz - lightOrigin;
        float ambientTerm = ao(isect.xyz,nor) + 0.4f;
        vec2 lighting = shadow(-lightDir,isect.xyz + nor * 0.1f);
        float intensity = lighting.x + ambientTerm;
        //intensity = ambientTerm;
        vec3 albedo = geomColors[int(isect.w)];
        
        vec3 h = (normalize(u_CamPos) + normalize(lightDir)) * 0.5f;
        float specularIntensity = max(pow(dot(h, nor), 10.f), 0.f);

        float diffuseTerm = 1.f - dot(normalize(vec4(nor,1)), normalize(vec4(lightDir,1)));
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f) + specularIntensity;

        res += (intensity * albedo.xyz * diffuseTerm) / float(numLights);
    }

    return vec4(res,1.f);
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
        out_Col = render(isect);

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

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

float displace(vec3 p) {
    //return sin(5.f * sin(20.f * p.x) + sin(20*p.y) + sin(20*p.z));
    float freq = 3.f;
    float octaves = 3.f;
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

float unionCSG(float d1, float d2) {
    return min(d1,d2);
}

float intersectionCSG(float d1, float d2) {
    return max(d1,d2);
}

float differenceCSG(float d1, float d2) {
    return max(-d1,d2);
}

float transformSDF(vec3 p) {
    vec3 twisted = twist(p);
    float sphere2 = sphere(twisted,2.f);

    p.x += -3.f;

    float normSphere = sphere(p, 1.5f);
    return unionCSG(sphere2 + displace(twisted), normSphere);
}



float epsilon = 0.01;
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(transformSDF(vec3(p.x + epsilon, p.y, p.z)) - transformSDF(vec3(p.x - epsilon, p.y, p.z)),
                                   transformSDF(vec3(p.x, p.y  + epsilon, p.z)) - transformSDF(vec3(p.x, p.y - epsilon, p.z)),
                                   transformSDF(vec3(p.x, p.y, p.z  + epsilon)) - transformSDF(vec3(p.x, p.y, p.z - epsilon))));
}

vec4 raymarch(vec3 rayDir, vec3 rayOrigin)
{
    //p is the far clip position we are casting to
    float tmax = 20.f;
    float t = 0.f;
    int maxSteps = 30;
    for(int i = 0; i < maxSteps; i++) {
        vec3 p = rayOrigin + rayDir * t;
        float dist = transformSDF(p);

        if (dist < 0.00001f) {
            return vec4(p,1);
        }

        t += dist;
        if(t > 1000.f) {
            return vec4(0);
        }

    }
    return vec4(0);
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
    if(isect.w > 0.00001) {
        vec3 nor = estimateNormal(isect.xyz);
        vec3 h = (normalize(u_CamPos) + normalize(fs_LightVec.xyz)) * 0.5f;
        float specularIntensity = max(pow(dot(h, nor), 2.f), 0.f);
        float diffuseTerm = 1.f - dot(normalize(vec4(nor,1)), normalize(fs_LightVec));
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);
        vec4 albedo = vec4(23.f,83.f,128.f,255.f) / 255.f;
        //diffuseTerm += specularIntensity;
        out_Col = albedo * diffuseTerm + specularIntensity;

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

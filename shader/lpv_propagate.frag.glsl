#version 330

uniform sampler2D LPV[3];

uniform int lpv_size;
uniform int lpv_cellsize;

in vec3 coord;
in vec2 ftexcoord;

vec4 SH_evaluateCosineLobe_direct( in vec3 dir );
vec4 SH_evaluate(vec3 dir);
ivec2 coord3Dto2D(vec4 pos, int lpv_size, int lpv_cellsize);
ivec4 coord2Dto3D(ivec2 coord, int lpv_size, int lpv_cellsize);

vec4 pack(vec4 value, float size);
vec4 unpack(vec4 value, float size);

layout(location = 0) out vec4 LPV_out[3];

ivec3 directions[6] = ivec3[](
    ivec3(1, 0, 0)
    , ivec3(-1, 0, 0)
    , ivec3(0, 1, 0)
    , ivec3(0, -1, 0)
    , ivec3(0, 0, 1)
    , ivec3(0, 0, -1)
);

vec4 calc_sh(sampler2D lpv, vec3 coord, vec3 dir){
    int lpv_size_h = lpv_size/2;
    ivec2 c2 = coord3Dto2D(vec4(coord, 1.0), lpv_size, 1);
    vec4 shcoeff = unpack(texelFetch(lpv, c2, 0), 8.0);
    vec4 dirSH = SH_evaluate(dir);
    vec4 dirCosineLobeSH = SH_evaluateCosineLobe_direct(dir);

    if((c2.x < 0) || (c2.x >= lpv_size))
        return vec4(0);
    else if((c2.y < 0) || (c2.y >= lpv_size*lpv_size))
        return vec4(0);
    else{
        float l = dot( shcoeff, dirSH );
        l = max(l, 0.0);
        return l * dirCosineLobeSH;
    }
}

void main(){
    vec4 shcoeff_accum[3] = vec4[](vec4(0), vec4(0), vec4(0));

    ivec4 cell_idx = coord2Dto3D(ivec2((coord.x/2+0.5)*lpv_size, (coord.y/2+0.5)*lpv_size*lpv_size), lpv_size, 1);

    for(int i=0; i<6; ++i){
        ivec3 dir = directions[i];
        ivec3 neighbor_cell_idx = cell_idx.xyz-dir;

        for(int j=0; j<3; ++j){
            shcoeff_accum[j] += calc_sh(LPV[j], neighbor_cell_idx, dir);
        }
    }

    for(int i=0; i<3; ++i){
        LPV_out[i] = pack(shcoeff_accum[i], 8.0);
        //LPV_out[i] = texelFetch(LPV[i], coord3Dto2D(cell_idx, lpv_size, 1), 0);
    }
}
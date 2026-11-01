// Framework Laptop 13 Pro boot screen: an ASCII cog in a starfield. Paste into shadertoy.com (Image tab).
// Every 18 s a glint crosses the cog like light over a CNC chamfer.
const float tagline = 1.0;   // 0.0 hides "(it's yours)"

float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec2 rows(float r0, float r1, float r2, float r3, float r4, float r5, float r6){
    return vec2(((r0 * 32.0 + r1) * 32.0 + r2) * 32.0 + r3, (r4 * 32.0 + r5) * 32.0 + r6);
}

// 5x7 bitmap glyphs, rows top to bottom, 16 = leftmost pixel.
vec2 glyph(float id){
    if (id < 0.5)  return rows(14.0, 17.0, 23.0, 21.0, 23.0, 16.0, 15.0); // @
    if (id < 1.5)  return rows(12.0, 18.0, 20.0,  8.0, 21.0, 18.0, 13.0); // &
    if (id < 2.5)  return rows( 0.0,  4.0, 21.0, 14.0, 21.0,  4.0,  0.0); // six-armed asterisk
    if (id < 3.5)  return rows( 0.0, 14.0, 17.0, 17.0, 17.0, 14.0,  0.0); // ring
    if (id < 4.5)  return rows( 0.0,  0.0,  0.0,  4.0,  0.0,  0.0,  0.0); // star dot
    if (id < 5.5)  return rows( 0.0,  0.0,  4.0, 14.0,  4.0,  0.0,  0.0); // star cross
    if (id < 6.5)  return rows( 2.0,  4.0,  8.0,  8.0,  8.0,  4.0,  2.0); // (
    if (id < 7.5)  return rows( 8.0,  4.0,  2.0,  2.0,  2.0,  4.0,  8.0); // )
    if (id < 8.5)  return rows( 4.0,  0.0, 12.0,  4.0,  4.0,  4.0, 14.0); // i
    if (id < 9.5)  return rows( 8.0,  8.0, 28.0,  8.0,  8.0,  9.0,  6.0); // t
    if (id < 10.5) return rows( 4.0,  4.0,  8.0,  0.0,  0.0,  0.0,  0.0); // '
    if (id < 11.5) return rows( 0.0,  0.0, 14.0, 16.0, 14.0,  1.0, 30.0); // s
    if (id < 12.5) return rows( 0.0,  0.0, 17.0, 17.0, 15.0,  1.0, 14.0); // y
    if (id < 13.5) return rows( 0.0,  0.0, 14.0, 17.0, 17.0, 17.0, 14.0); // o
    if (id < 14.5) return rows( 0.0,  0.0, 17.0, 17.0, 17.0, 19.0, 13.0); // u
    if (id < 15.5) return rows( 0.0,  0.0, 22.0, 25.0, 16.0, 16.0, 16.0); // r
    return vec2(0.0);                                                     // space
}

// "(it's yours)" as glyph ids.
float taglineChar(float k){
    if (k < 0.5)  return 6.0;
    if (k < 1.5)  return 8.0;
    if (k < 2.5)  return 9.0;
    if (k < 3.5)  return 10.0;
    if (k < 4.5)  return 11.0;
    if (k < 5.5)  return 16.0;
    if (k < 6.5)  return 12.0;
    if (k < 7.5)  return 13.0;
    if (k < 8.5)  return 14.0;
    if (k < 9.5)  return 15.0;
    if (k < 10.5) return 11.0;
    return 7.0;
}

// Coverage of glyph g at cell-local position l in [0,1)^2: a 5x7 bitmap on an 8x8 pixel cell.
float ink(vec2 g, vec2 l){
    vec2 px = floor(l * 8.0);
    float col = px.x - 1.0;
    float row = 6.0 - px.y;
    if (col < 0.0 || col > 4.0 || row < 0.0) return 0.0;
    float bits = row < 3.5 ? mod(floor(g.x / exp2(5.0 * (3.0 - row))), 32.0)
                           : mod(floor(g.y / exp2(5.0 * (6.0 - row))), 32.0);
    return mod(floor(bits / exp2(4.0 - col)), 2.0);
}

// Signed distance-like field of the six-lobed cog, in units of its outer radius (negative inside).
float cog(vec2 q){
    float r = length(q);
    float a = atan(q.y, q.x);
    float outer = 1.0 - 0.16 * pow(0.5 - 0.5 * cos(6.0 * a), 3.0);
    return max(r - outer, 0.6 - r);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 res = iResolution.xy;
    vec2 uv = fragCoord / res;
    float t = iTime;

    float cs = res.y / 100.0;                 // cell size in px
    vec2 g = (fragCoord - 0.5 * res) / cs;    // cell space, origin at screen centre
    vec2 c = floor(g);
    vec2 l = g - c;
    vec2 cc = c + 0.5;

    const float R = 30.0;                     // cog radius in cells
    float ang = t * 6.2831853 / 900.0;        // one turn per 15 minutes
    mat2 rot = mat2(cos(ang), -sin(ang), sin(ang), cos(ang));

    vec3 lavender = vec3(0.90, 0.89, 0.96);
    vec3 orange = vec3(1.00, 0.29, 0.11);
    vec3 starCol = vec3(0.79, 0.80, 0.91);

    // graphite backdrop, lifted toward the upper left like the studio shots
    vec3 col = mix(vec3(0.018, 0.018, 0.024), vec3(0.060, 0.060, 0.072),
                   smoothstep(1.2, 0.0, length((uv - vec2(0.0, 1.0)) * vec2(res.x / res.y, 1.0)) * 0.8));

    // glint: time since its front last crossed this cell
    vec2 dir = normalize(vec2(1.0, -0.6));
    float since = mod(t - (dot(cc, dir) + 120.0) / 45.0, 18.0);
    float sheen = exp(-since * 2.2);

    float inCog = step(cog(rot * cc / R), 0.0);

    vec3 cellCol = vec3(0.0);
    float cellInk = 0.0;
    if (inCog > 0.5){
        float id = floor(hash(c) * 4.0);
        bool ember = hash(c + 41.7) < 0.003;
        float lum = 0.72 + 0.20 * hash(c + 7.3) + 0.45 * sheen;
        cellInk = ink(glyph(id), l);
        cellCol = ember ? orange * (0.85 + 0.15 * sin(t * 1.3 + hash(c + 29.1) * 30.0)) : lavender * lum;
        if (ember) col += orange * 0.22 * exp(-length(l - 0.5) * 3.5);
    } else {
        float h = hash(c + 91.7);
        if (h < 0.010){
            float id = hash(c + 13.1) < 0.3 ? 5.0 : 4.0;
            float tw = 0.55 + 0.45 * sin(t * (0.4 + hash(c + 3.3)) + hash(c + 5.9) * 40.0);
            cellInk = ink(glyph(id), l);
            cellCol = starCol * (0.25 + 0.45 * hash(c + 2.2)) * tw;
        }
    }

    // "(it's yours)" on the grid, clear of the rotating cog
    vec2 tc = c - vec2(12.0, -33.0);
    if (tagline > 0.5 && tc.y == 0.0 && tc.x >= 0.0 && tc.x < 12.0){
        cellInk = ink(glyph(taglineChar(tc.x)), l);
        cellCol = orange * 0.95;
    }

    col = mix(col, cellCol, cellInk);

    // faint halo around the cog
    float d = cog(rot * g / R) * R;
    col += lavender * exp(-max(d, 0.0) * 0.35) * 0.025;

    col *= 1.0 - 0.35 * dot(uv - 0.5, uv - 0.5);
    col += (hash(fragCoord + fract(t)) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}

#version 300 es
precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 color = texture(tex, v_texcoord);
    // Standard luminance formula
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    // Boost contrast slightly for that crisp 1-bit terminal feel
    gray = smoothstep(0.1, 0.9, gray);
    fragColor = vec4(vec3(gray), color.a);
}

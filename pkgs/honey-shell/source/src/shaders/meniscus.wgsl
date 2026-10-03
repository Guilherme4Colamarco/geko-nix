// Static inner light, clipped to the rounded central body, with no time dependency.
fn shade(s: Shader) -> vec4<f32> {
    let r = max(s.a.y, 1.0);
    let q = abs(s.pos - s.size * 0.5) - s.size * 0.5 + vec2<f32>(r);
    let sdf = length(max(q, vec2<f32>(0.0))) + min(max(q.x, q.y), 0.0) - r;
    let mask = 1.0 - smoothstep(-1.0, 1.0, sdf);
    let edge = pow(abs(s.uv.x * 2.0 - 1.0), 8.0);
    let light = edge * 0.035 + pow(1.0 - s.uv.y, 12.0) * 0.06;
    return vec4<f32>(s.color.rgb, light * mask * s.a.x);
}

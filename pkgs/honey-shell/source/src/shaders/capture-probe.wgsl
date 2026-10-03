// Diagnostic only: green means the runtime knows the background; red means fallback.
fn shade(s: Shader) -> vec4<f32> {
    let bg = behind(s, s.pos);
    if (bg.a > 0.5) { return vec4<f32>(0.1, 0.95, 0.2, 0.45); }
    return vec4<f32>(0.95, 0.1, 0.1, 0.45);
}

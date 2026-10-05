# pleamar-wm do upstream com o patch de framebuffer linear (pkgs/pleamar-linear-framebuffer.patch).
{ upstream }:
upstream.overrideAttrs (old: {
  patches = (old.patches or []) ++ [ ./pleamar-linear-framebuffer.patch ];
})

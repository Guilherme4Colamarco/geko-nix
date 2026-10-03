{ upstream }:
upstream.overrideAttrs (old: {
  patches = (old.patches or []) ++ [ ./pleamar-linear-framebuffer.patch ];
})

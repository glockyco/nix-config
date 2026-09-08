{ plannotator }:

# Base: v0.27.12 (96313ab228ede843203d38d9d2a86e1c87e18c81).
# Fix: 420ee6c0bca735eece1d623aa7bfe25445c82771, retained downstream.
# Preserve the pinned recipe, dependency cache, and existing packaging patches.
plannotator.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./plannotator-client-lease.patch ];
})

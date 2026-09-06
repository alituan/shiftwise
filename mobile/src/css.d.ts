// Ambient declaration for the global.css side-effect import (app/_layout.tsx).
// Uniwind's Metro plugin processes the file at build time; this only
// satisfies the TypeScript compiler, it has no runtime effect.
declare module '*.css';

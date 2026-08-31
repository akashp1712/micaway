import path from "node:path";

/** @param {string[]} filenames */
function biomeFormat(filenames) {
  const rel = filenames.map((f) => path.relative(process.cwd(), f) || f);
  const biome = path.join(process.cwd(), "node_modules/.bin/biome");
  const quoted = rel.map((f) => `"${f.replace(/"/g, '\\"')}"`).join(" ");
  // Format only on commit — full `pnpm lint` still runs ultracite/biome rules separately
  return `${biome} format --write --files-ignore-unknown=true ${quoted}`;
}

export default {
  "*.{js,jsx,ts,tsx,mjs,cjs,json,jsonc,css}": biomeFormat,
};

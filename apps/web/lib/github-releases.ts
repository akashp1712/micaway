const githubHeaders: HeadersInit = {
  Accept: "application/vnd.github+json",
  "User-Agent": "micaway-web",
  "X-GitHub-Api-Version": "2022-11-28",
  ...(process.env.GITHUB_TOKEN
    ? { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` }
    : {}),
};

export interface ReleaseAsset {
  browser_download_url: string;
  download_count: number;
  name: string;
}

export interface GitHubRelease {
  assets: ReleaseAsset[];
  tag_name: string;
}

export function isAppZip(name: string) {
  return name.startsWith("MicAway-") && name.endsWith(".zip");
}

export async function getGithubReleases() {
  const response = await fetch(
    "https://api.github.com/repos/akashp1712/micaway/releases?per_page=100",
    {
      headers: githubHeaders,
      next: { revalidate: 60 },
    }
  );

  if (!response.ok) {
    throw new Error("GitHub releases unavailable");
  }

  return (await response.json()) as GitHubRelease[];
}

export function zipDownloads(releases: GitHubRelease[]) {
  return releases
    .flatMap((release) => release.assets)
    .filter((asset) => isAppZip(asset.name))
    .reduce((total, asset) => total + asset.download_count, 0);
}

export function latestZipUrl(releases: GitHubRelease[]) {
  for (const release of releases) {
    const zip = release.assets.find((asset) => isAppZip(asset.name));
    if (zip) {
      return zip.browser_download_url;
    }
  }

  return null;
}

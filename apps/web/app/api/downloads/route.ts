import { NextResponse } from "next/server";

interface GitHubRelease {
  assets: Array<{
    download_count: number;
    name: string;
  }>;
  tag_name: string;
}

export const revalidate = 3600;

function zipDownloads(releases: GitHubRelease[]) {
  return releases
    .flatMap((release) => release.assets)
    .filter(
      (asset) =>
        asset.name.startsWith("MicAway-") && asset.name.endsWith(".zip")
    )
    .reduce((total, asset) => total + asset.download_count, 0);
}

export async function GET() {
  try {
    const response = await fetch(
      "https://api.github.com/repos/akashp1712/micaway/releases?per_page=100",
      {
        headers: {
          Accept: "application/vnd.github+json",
          "X-GitHub-Api-Version": "2022-11-28",
          ...(process.env.GITHUB_TOKEN
            ? { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` }
            : {}),
        },
        next: { revalidate },
      }
    );

    if (!response.ok) {
      return NextResponse.json(
        { error: "GitHub download count unavailable" },
        { status: 502 }
      );
    }

    const releases = (await response.json()) as GitHubRelease[];

    return NextResponse.json({
      downloads: zipDownloads(releases),
      source: "github_releases",
    });
  } catch {
    return NextResponse.json(
      { error: "GitHub download count unavailable" },
      { status: 502 }
    );
  }
}

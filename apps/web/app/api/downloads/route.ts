import { NextResponse } from "next/server";
import { getGithubReleases, zipDownloads } from "@/lib/github-releases";

export const revalidate = 60;

export async function GET() {
  try {
    const releases = await getGithubReleases();

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

import { NextResponse } from "next/server";
import { getGithubReleases, latestZipUrl } from "@/lib/github-releases";

const releasesPage = "https://github.com/akashp1712/micaway/releases/latest";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const url = latestZipUrl(await getGithubReleases()) ?? releasesPage;
    return NextResponse.redirect(url, 302);
  } catch {
    return NextResponse.redirect(releasesPage, 302);
  }
}

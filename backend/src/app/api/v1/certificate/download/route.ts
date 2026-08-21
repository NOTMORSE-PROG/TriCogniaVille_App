import { NextRequest, NextResponse } from "next/server";
import { verifyToken } from "@/lib/auth/jwt";
import { db } from "@/lib/db";
import { buildingStates, students } from "@/lib/db/schema";
import { eq, and } from "drizzle-orm";
import { badRequest, unauthorized, notFound, internalError } from "@/lib/api/errors";
import {
  generateCertificateJpg,
  generateCertificatePdf,
  sanitizeFilename,
} from "@/lib/certificate/generate";

const REQUIRED_BUILDINGS = 8;

function extractBearerToken(request: NextRequest): string | null {
  const authHeader = request.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;
  return authHeader.slice(7);
}

export async function GET(request: NextRequest) {
  // Accept token from Authorization header OR query param
  // (query param needed for OS.shell_open browser downloads)
  const headerToken = extractBearerToken(request);
  const queryToken = new URL(request.url).searchParams.get("token");
  const token = headerToken || queryToken;

  if (!token) {
    return unauthorized("Missing authorization token");
  }

  let payload;
  try {
    payload = await verifyToken(token);
  } catch {
    return unauthorized("Invalid or expired token");
  }

  if (payload.role !== "student") {
    return unauthorized("Student access required");
  }

  try {
    // Verify completion: count unlocked buildings
    const unlockedRows = await db
      .select({ buildingId: buildingStates.buildingId })
      .from(buildingStates)
      .where(
        and(
          eq(buildingStates.studentId, payload.sub),
          eq(buildingStates.unlocked, true)
        )
      );

    if (unlockedRows.length < REQUIRED_BUILDINGS) {
      return badRequest(
        `Certificate requires all ${REQUIRED_BUILDINGS} buildings to be unlocked (currently ${unlockedRows.length})`
      );
    }

    // Get student name
    const [student] = await db
      .select({ name: students.name })
      .from(students)
      .where(eq(students.id, payload.sub))
      .limit(1);

    if (!student) {
      return notFound("Student not found");
    }

    // Parse format
    const format =
      new URL(request.url).searchParams.get("format") ?? "jpg";
    if (format !== "jpg" && format !== "pdf") {
      return badRequest("format must be 'jpg' or 'pdf'");
    }

    const safeName = sanitizeFilename(student.name);

    if (format === "pdf") {
      const pdfBuffer = await generateCertificatePdf(student.name);
      return new NextResponse(new Uint8Array(pdfBuffer), {
        headers: {
          "Content-Type": "application/pdf",
          "Content-Disposition": `attachment; filename="TriCognia-Certificate-${safeName}.pdf"`,
          "Cache-Control": "private, max-age=3600",
        },
      });
    }

    const jpgBuffer = await generateCertificateJpg(student.name);
    return new NextResponse(new Uint8Array(jpgBuffer), {
      headers: {
        "Content-Type": "image/jpeg",
        "Content-Disposition": `attachment; filename="TriCognia-Certificate-${safeName}.jpg"`,
        "Cache-Control": "private, max-age=3600",
      },
    });
  } catch (error) {
    console.error("Certificate generation error:", error);
    return internalError();
  }
}

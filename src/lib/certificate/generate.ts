import sharp from "sharp";
import { PDFDocument } from "pdf-lib";
import path from "path";
import fs from "fs/promises";

const TEMPLATE_PATH = path.join(process.cwd(), "public", "cert-template.jpg");

// Template dimensions
const TEMPLATE_W = 2000;
const TEMPLATE_H = 1414;

// Name overlay position — confirmed via visual marker test (y=710 sits cleanly
// below "THIS CERTIFIES THAT" and above the underline)
const NAME_Y = 710;
const NAME_X = 1000; // horizontal center

function sanitizeName(name: string): string {
  return name.replace(/[<>&"']/g, "").slice(0, 60);
}

function getFontSize(name: string): number {
  const len = name.length;
  if (len <= 20) return 88;
  if (len <= 35) return 70;
  return 55;
}

export async function generateCertificateJpg(
  studentName: string
): Promise<Buffer> {
  const template = await fs.readFile(TEMPLATE_PATH);
  const safeName = sanitizeName(studentName);
  const fontSize = getFontSize(safeName);

  const svgOverlay = `
    <svg width="${TEMPLATE_W}" height="${TEMPLATE_H}" xmlns="http://www.w3.org/2000/svg">
      <text
        x="${NAME_X}"
        y="${NAME_Y}"
        font-family="Georgia, 'Times New Roman', serif"
        font-size="${fontSize}"
        font-weight="bold"
        font-style="italic"
        fill="#1a0a3e"
        stroke="#1a0a3e"
        stroke-width="1.5"
        text-anchor="middle"
        dominant-baseline="middle"
        letter-spacing="3"
      >${safeName}</text>
    </svg>`;

  // Render the SVG to an exact-size PNG layer first to avoid DPI scaling issues
  // (librsvg can render SVGs at non-1:1 scale depending on system DPI)
  const textLayer = await sharp(Buffer.from(svgOverlay))
    .resize(TEMPLATE_W, TEMPLATE_H, { fit: "fill" })
    .png()
    .toBuffer();

  const result = await sharp(template)
    .composite([{ input: textLayer, top: 0, left: 0 }])
    .jpeg({ quality: 92 })
    .toBuffer();

  return result;
}

export async function generateCertificatePdf(
  studentName: string
): Promise<Buffer> {
  const jpgBuffer = await generateCertificateJpg(studentName);

  const pdfDoc = await PDFDocument.create();
  // Landscape page matching the certificate aspect ratio
  const pageWidth = 792; // ~11 inches at 72 dpi
  const pageHeight = pageWidth * (TEMPLATE_H / TEMPLATE_W); // ~560

  const page = pdfDoc.addPage([pageWidth, pageHeight]);
  const jpgImage = await pdfDoc.embedJpg(jpgBuffer);
  page.drawImage(jpgImage, {
    x: 0,
    y: 0,
    width: pageWidth,
    height: pageHeight,
  });

  const pdfBytes = await pdfDoc.save();
  return Buffer.from(pdfBytes);
}

export function sanitizeFilename(name: string): string {
  return name.replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 40);
}

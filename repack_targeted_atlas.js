const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

function scaleQuarterInt(value) {
  return Math.max(1, Math.round(value / 4));
}

function parseTextureRect(value) {
  const m = value.match(/^\{\{(-?\d+),(-?\d+)\},\{(-?\d+),(-?\d+)\}\}$/);
  if (!m) throw new Error(`Unsupported textureRect: ${value}`);
  return {
    x: parseInt(m[1], 10),
    y: parseInt(m[2], 10),
    width: parseInt(m[3], 10),
    height: parseInt(m[4], 10),
  };
}

async function main() {
  const plistPath = process.argv[2];
  if (!plistPath) throw new Error('Usage: node repack_targeted_atlas.js <plistPath>');

  let content = fs.readFileSync(plistPath, 'utf8');
  if (!content.includes('<key>frames</key>') || !content.includes('<key>metadata</key>')) {
    throw new Error('Not an atlas plist');
  }

  const textureMatch = content.match(/<key>textureFileName<\/key>\s*<string>([^<]+)<\/string>/);
  if (!textureMatch) throw new Error('textureFileName not found');

  const textureDir = path.dirname(plistPath);
  const textureFileName = path.basename(textureMatch[1]);
  const texturePath = path.join(textureDir, textureFileName);
  const newTextureFileName = `${path.parse(textureFileName).name}.repack.png`;
  const newTexturePath = path.join(textureDir, newTextureFileName);

  const framePattern = /<key>([^<]+)<\/key>\s*<dict>.*?<key>textureRect<\/key>\s*<string>(\{\{[^<]+\}\})<\/string>.*?<key>textureRotated<\/key>\s*<(true|false)\/>.*?<\/dict>/gs;
  const matches = [...content.matchAll(framePattern)];

  const source = sharp(texturePath, { animated: false });
  const meta = await source.metadata();
  const atlasWidth = Math.max(64, scaleQuarterInt(meta.width));
  const padding = 1;

  const entries = [];
  let x = padding;
  let y = padding;
  let rowHeight = 0;

  for (const match of matches) {
    const originalRect = match[2];
    const rotated = match[3] === 'true';
    const rect = parseTextureRect(originalRect);
    const safeLeft = Math.max(0, Math.min(rect.x, Math.max(0, meta.width - 1)));
    const safeTop = Math.max(0, Math.min(rect.y, Math.max(0, meta.height - 1)));
    const maxWidth = Math.max(1, meta.width - safeLeft);
    const maxHeight = Math.max(1, meta.height - safeTop);
    const sourceWidth = rotated ? rect.height : rect.width;
    const sourceHeight = rotated ? rect.width : rect.height;
    const safeWidth = Math.max(1, Math.min(sourceWidth, maxWidth));
    const safeHeight = Math.max(1, Math.min(sourceHeight, maxHeight));
    const width = scaleQuarterInt(safeWidth);
    const height = scaleQuarterInt(safeHeight);
    if (x + width + padding > atlasWidth) {
      x = padding;
      y += rowHeight + padding;
      rowHeight = 0;
    }

    entries.push({ originalRect, rotated, rect, safeLeft, safeTop, safeWidth, safeHeight, x, y, width, height });
    x += width + padding;
    rowHeight = Math.max(rowHeight, height);
  }

  const atlasHeight = Math.max(1, y + rowHeight + padding);
  const composites = [];

  for (const entry of entries) {
    let pipeline = sharp(texturePath)
      .extract({ left: entry.safeLeft, top: entry.safeTop, width: entry.safeWidth, height: entry.safeHeight });

    let buffer;
    try {
      buffer = await pipeline
        .resize(entry.width, entry.height, { fit: 'fill', kernel: sharp.kernel.cubic })
        .png()
        .toBuffer();
    } catch (err) {
      console.error('REPACK_FAIL', path.basename(plistPath), entry);
      throw err;
    }

    composites.push({ input: buffer, left: entry.x, top: entry.y });

    const escaped = entry.originalRect.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const newRect = `{{${entry.x},${entry.y}},{${entry.width},${entry.height}}}`;
    content = content.replace(new RegExp(escaped), newRect);
  }

  await sharp({
    create: {
      width: atlasWidth,
      height: atlasHeight,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite(composites)
    .png()
    .toFile(newTexturePath);

  content = content.replace(/(<key>size<\/key>\s*<string>)\{[^<]+\}(<\/string>)/, `$1{${atlasWidth},${atlasHeight}}$2`);
  content = content.replace(/(<key>textureFileName<\/key>\s*<string>)[^<]+(<\/string>)/, `$1${newTextureFileName}$2`);
  content = content.replace(/(<key>realTextureFileName<\/key>\s*<string>)[^<]+(<\/string>)/, `$1${newTextureFileName}$2`);
  content = content.replace(/(<key>textureRotated<\/key>\s*)<true\/>/g, '$1<false/>');
  fs.writeFileSync(plistPath, content, 'utf8');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

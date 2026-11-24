// Draws a 1024x1024 PNG: the Chrome icon with a round profile badge in the bottom-right corner.
// The badge is the profile picture, or a coloured circle with the profile's initial when there is none.
// Run: osascript -l JavaScript lib/badge.js <base.icns> <picture.png or ""> <profile name> <hue 0-1> <out.png>
ObjC.import('AppKit');

function run(argv) {
  const [basePath, picPath, name, hue, outPath] = argv;
  const initial = (Array.from(name.trim())[0] || "?").toUpperCase();
  const N = 1024;
  const rep = $.NSBitmapImageRep.alloc.initWithBitmapDataPlanesPixelsWidePixelsHighBitsPerSampleSamplesPerPixelHasAlphaIsPlanarColorSpaceNameBytesPerRowBitsPerPixel(
    null, N, N, 8, 4, true, false, $.NSDeviceRGBColorSpace, 0, 0);
  $.NSGraphicsContext.saveGraphicsState;
  $.NSGraphicsContext.setCurrentContext($.NSGraphicsContext.graphicsContextWithBitmapImageRep(rep));

  const base = $.NSImage.alloc.initWithContentsOfFile(basePath);
  base.drawInRectFromRectOperationFraction($.NSMakeRect(0, 0, N, N), $.NSZeroRect, $.NSCompositingOperationSourceOver, 1);

  const d = 500;
  const ring = $.NSMakeRect(N - d - 30, 30, d, d);
  $.NSColor.whiteColor.setFill;
  $.NSBezierPath.bezierPathWithOvalInRect(ring).fill;
  const inner = $.NSMakeRect(N - d - 30 + 22, 52, d - 44, d - 44);

  $.NSGraphicsContext.saveGraphicsState;
  $.NSBezierPath.bezierPathWithOvalInRect(inner).addClip;
  const pic = picPath ? $.NSImage.alloc.initWithContentsOfFile(picPath) : null;
  if (pic && !pic.isNil()) {
    pic.drawInRectFromRectOperationFraction(inner, $.NSZeroRect, $.NSCompositingOperationSourceOver, 1);
  } else {
    $.NSColor.colorWithCalibratedHueSaturationBrightnessAlpha(parseFloat(hue), 0.55, 0.6, 1).setFill;
    $.NSBezierPath.fillRect(inner);
    const attrs = $.NSMutableDictionary.dictionary;
    attrs.setObjectForKey($.NSFont.boldSystemFontOfSize(260), $.NSFontAttributeName);
    attrs.setObjectForKey($.NSColor.whiteColor, $.NSForegroundColorAttributeName);
    const s = $.NSString.stringWithString(initial);
    const size = s.sizeWithAttributes(attrs);
    s.drawAtPointWithAttributes(
      $.NSMakePoint(inner.origin.x + (inner.size.width - size.width) / 2, inner.origin.y + (inner.size.height - size.height) / 2),
      attrs);
  }
  $.NSGraphicsContext.restoreGraphicsState;
  $.NSGraphicsContext.restoreGraphicsState;

  const png = rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $.NSDictionary.dictionary);
  if (!png.writeToFileAtomically(outPath, true)) throw new Error('Cannot write ' + outPath);
}

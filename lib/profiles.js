// Lists Chrome profiles from "Local State": one line per profile, tab-separated:
//   <directory>\t<name>\t<avatar picture path or empty>
// Run: osascript -l JavaScript lib/profiles.js "<Chrome user data dir>"
ObjC.import('Foundation');

function run(argv) {
  const dataDir = argv[0];
  const text = $.NSString.stringWithContentsOfFileEncodingError(dataDir + '/Local State', $.NSUTF8StringEncoding, null);
  if (text.isNil()) throw new Error('Cannot read ' + dataDir + '/Local State');
  const cache = ((JSON.parse(text.js).profile || {}).info_cache) || {};
  const fm = $.NSFileManager.defaultManager;
  const dirs = Object.keys(cache).sort((a, b) => {
    // Default first, then Profile 1, Profile 2, ... in number order.
    const n = (d) => (d === 'Default' ? -1 : parseInt(d.replace(/\D/g, ''), 10) || 0);
    return n(a) - n(b);
  });
  return dirs
    .map((dir) => {
      const pic = dataDir + '/' + dir + '/Google Profile Picture.png';
      const name = (cache[dir].name || dir).replace(/[\t\n]/g, ' ');
      return [dir, name, fm.fileExistsAtPath(pic) ? pic : ''].join('\t');
    })
    .join('\n');
}

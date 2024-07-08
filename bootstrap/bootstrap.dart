import 'dart:io';
import 'package:path/path.dart';

// helpers
map(f, xs) => xs.map(f).toList();
tail(xs, [i = 1]) => xs.sublist(i);
filter(f, List xs) => xs.where((x) => f(x)).toList();
flatten(List xs) => xs.expand((x) => x).toList();
unique(xs) => xs.toSet().toList();
fileExists(filePath) => File(filePath).existsSync();
getConts(filePath) => (filePath, File(filePath).readAsLinesSync());
overwrite(filePath, conts) {
  if (fileExists(filePath) == true) File(filePath).deleteSync();
  new File(filePath).createSync(recursive: true);
  File(filePath).writeAsStringSync(conts + '\n');
}

// program
main(args) {
  var inpFiles = unique(filter(fileExists, args));
  var flConts = map(getConts, inpFiles);
  var tangleBlks = flatten(map((fl) => getBlks("tangle", fl), flConts));
  var expandedBlks = map(expandRefs, tangleBlks);
  for (var blk in expandedBlks) overwrite(blk.$1, blk.$2.join('\n'));
}

getBlks(blkType, flConts) {
  var outBlks = [];

  var lnConts = List.from(flConts.$2);
  while (lnConts.length > 3) {
    if (((blkType == "tangle" &&
                RegExp(r'^(\`.+\` \| )?\[.+\]\(.+\):$').hasMatch(lnConts[0]) ==
                    false) ||
            (blkType == "named" &&
                RegExp(r'^\`.+\`( \| \[.+\]\(.+\))?:$').hasMatch(lnConts[0]) ==
                    false)) ||
        (RegExp(r'^```+').hasMatch(lnConts[1]) == false)) {
      lnConts = tail(lnConts, 2);
      continue;
    }

    var lnm = flConts.$2.length - lnConts.length;
    var desc = flConts.$2[lnm];
    var open = flConts.$2[lnm + 1];
    var fwd_lnm = lnm +
        3 +
        tail(lnConts, 3)
            .indexWhere((ln) => ln == RegExp(r'^``+').firstMatch(open)?[0]);

    var nm_or_out = switch (blkType) {
      "tangle" when desc[0] == '`' => join(dirname(flConts.$1),
          RegExp(r'(?<=^\`.+\` \| \[.+\]\().+(?=\):$)').firstMatch(desc)?[0]),
      "tangle" when desc[0] == '[' => join(dirname(flConts.$1),
          RegExp(r'(?<=^\[.+\]\().+(?=\):$)').firstMatch(desc)?[0]),
      "named" when desc[0] == '`' =>
        RegExp(r'(?<=^\`).+(?=`)').firstMatch(desc)?[0],
      "named" when desc[0] == '[' =>
        RegExp(r'(?<=^\[).+(?=\]\(.+\):$)').firstMatch(desc)?[0],
      _ => "NONE",
    };
    var blkConts = flConts.$2.sublist(lnm + 2, fwd_lnm);

    outBlks.add((nm_or_out, flConts.$1, blkConts));
    lnConts = tail(flConts.$2, fwd_lnm + 1);
  }

  return outBlks;
}

expandRefs(blk) {
  var newConts = [];
  var inBlock = false;

  for (var ln in blk.$3) {
    if (RegExp(r'^```+').hasMatch(ln) == true) inBlock = !inBlock;
    if (RegExp(r'<<<.+>>>').hasMatch(ln) == false || inBlock == true) {
      newConts.add(ln);
      continue;
    }

    var ref = RegExp(r'(?<=^.*<<<).+(?=>>>.*$)').firstMatch(ln)?[0]?.split(':');
    var (refFile, refName) = switch (ref) {
      [var fl, var name] => (join(dirname(blk.$2), fl), name),
      _ => (blk.$2, ref?[0]),
    };
    if (fileExists(refFile) == false) {
      newConts.add(ln);
      continue;
    }

    var refBlk = getBlks("named", getConts(refFile))
        .firstWhere((blk) => blk.$1 == refName, orElse: () => []);
    if (refBlk == []) {
      newConts.add(ln);
      continue;
    }
    var expRefBlk = expandRefs(refBlk);

    var prefix = ln.split("<<<")[0];
    var suffix = ln.split(">>>")[1];
    for (var refLn in expRefBlk.$2) {
      if (refLn == "") {
        newConts.add("");
        continue;
      }

      newConts.add(prefix + refLn + suffix);
    }
    continue;
  }
  return (blk.$1, newConts);
}

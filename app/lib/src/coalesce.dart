// SPDX-License-Identifier: Apache-2.0
/// One run at a time, and at most one more behind it: a request that comes while a run is going
/// marks a single rerun that starts when the run ends; further requests in the meantime merge
/// into it: the one with the higher `rank` is the rerun, and of equal rank the latest.
library;

class Coalesced {
  bool _running = false;
  bool _again = false;
  Future<int> Function()? _latest;
  int _latestRank = 0;

  bool get running => _running;

  /// Runs [body] now, or, when a run is going, marks one rerun and returns 0 at once. The rerun
  /// is the [body] of the highest [rank] given meanwhile, the latest of those of equal rank (a
  /// check of every contact outranks a check of a few). The caller that started the runs gets
  /// the sum of all of them.
  Future<int> run(Future<int> Function() body, {int rank = 0}) async {
    if (_running) {
      if (!_again || rank >= _latestRank) {
        _latest = body;
        _latestRank = rank;
      }
      _again = true;
      return 0;
    }
    _running = true;
    try {
      var total = 0;
      var next = body;
      do {
        _again = false;
        total += await next();
        next = _latest ?? body;
      } while (_again);
      return total;
    } finally {
      _running = false;
      _again = false;
      _latest = null;
      _latestRank = 0;
    }
  }
}

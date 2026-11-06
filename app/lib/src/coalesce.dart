// SPDX-License-Identifier: Apache-2.0
/// One run at a time, and at most one more behind it: a request that comes while a run is going
/// marks a single rerun that starts when the run ends; further requests in the meantime add
/// nothing.
library;

class Coalesced {
  bool _running = false;
  bool _again = false;

  bool get running => _running;

  /// Runs [body] now, or, when a run is going, marks one rerun and returns 0 at once. The caller
  /// that started the runs gets the sum of all of them.
  Future<int> run(Future<int> Function() body) async {
    if (_running) {
      _again = true;
      return 0;
    }
    _running = true;
    try {
      var total = 0;
      do {
        _again = false;
        total += await body();
      } while (_again);
      return total;
    } finally {
      _running = false;
      _again = false;
    }
  }
}

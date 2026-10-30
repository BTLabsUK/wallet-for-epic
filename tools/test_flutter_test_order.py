# SPDX-License-Identifier: Apache-2.0
# Unit tests for flutter_test_order.py: the order, the times read from flutter's json reporter and
# the times file it keeps.
#   python3 -m unittest tools/test_flutter_test_order.py
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import flutter_test_order as fto  # noqa: E402

APP = "/w/app"


def events(*items):
    return [json.dumps(e) for e in items]


RUN = events(
    {"type": "start", "time": 0},
    {"type": "suite", "suite": {"id": 0, "path": f"{APP}/test/a_test.dart"}, "time": 100},
    {"type": "testStart", "test": {"id": 1, "suiteID": 0, "name": "loading"}, "time": 100},
    {"type": "testDone", "testID": 1, "hidden": True, "time": 900},
    {"type": "testStart", "test": {"id": 2, "suiteID": 0, "name": "a one"}, "time": 900},
    {"type": "testDone", "testID": 2, "result": "success", "time": 2600},
    {"type": "suite", "suite": {"id": 3, "path": f"{APP}/test/d/b_test.dart"}, "time": 200},
    {"type": "testStart", "test": {"id": 4, "suiteID": 3, "name": "b one"}, "time": 300},
    {"type": "testDone", "testID": 4, "result": "error", "time": 700},
    "not json",
    {"type": "suite", "suite": {"id": 9}, "time": 5},
    {"type": "testStart", "time": 5},
    {"type": "testDone", "testID": 77, "time": 6},
    {"type": "done", "success": False, "time": 2700},
)


class OrderTest(unittest.TestCase):
    def test_unknown_first_then_slowest_then_name(self):
        times = {"test/a_test.dart": 5.0, "test/b_test.dart": 300.0, "test/c_test.dart": 5.0}
        files = ["test/c_test.dart", "test/a_test.dart", "test/new_test.dart", "test/b_test.dart"]
        self.assertEqual(fto.order(files, times),
                         ["test/new_test.dart", "test/b_test.dart", "test/a_test.dart",
                          "test/c_test.dart"])

    def test_same_files_whatever_the_times(self):
        files = [f"test/{i}_test.dart" for i in range(50)]
        times = {f: float(i % 7) for i, f in enumerate(files[::2])}
        self.assertEqual(sorted(fto.order(files, times)), sorted(files))
        self.assertEqual(sorted(fto.order(files, {})), sorted(files))

    def test_bad_times_file_counts_as_empty(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "t.json"
            self.assertEqual(fto.read_times(str(p)), {})
            p.write_text("[1, 2]")
            self.assertEqual(fto.read_times(str(p)), {})
            p.write_text("{broken")
            self.assertEqual(fto.read_times(str(p)), {})
            p.write_text('{"x": "nan?", "y": NaN, "z": Infinity, "w": null, "ok": 3}')
            self.assertEqual(fto.read_times(str(p)), {"ok": 3.0})


class RecordTest(unittest.TestCase):
    def test_run_times_per_file_from_suite_start_to_last_test(self):
        self.assertEqual(fto.run_times(RUN, APP),
                         {"test/a_test.dart": 2.5, "test/d/b_test.dart": 0.5})

    def test_record_merges_into_the_times_file(self):
        with tempfile.TemporaryDirectory() as d:
            times, run = Path(d) / "sub" / "t.json", Path(d) / "run.json"
            run.write_text("\n".join(RUN))
            times.parent.mkdir()
            times.write_text(json.dumps({"test/a_test.dart": 99.0, "test/old_test.dart": 7.0}))
            fto.record(str(times), str(run), APP)
            self.assertEqual(json.loads(times.read_text()),
                             {"test/a_test.dart": 2.5, "test/d/b_test.dart": 0.5,
                              "test/old_test.dart": 7.0})


if __name__ == "__main__":
    unittest.main()

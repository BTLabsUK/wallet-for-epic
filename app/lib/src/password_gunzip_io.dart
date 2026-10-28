// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

List<int> gunzip(List<int> bytes) => gzip.decode(bytes);

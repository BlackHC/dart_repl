// Copyright (c) 2016, Andreas 'blackhc' Kirsch. All rights reserved. Use of
// this source code is governed by a BSD-style license that can be found in the
// LICENSE file.

const int RESET_RESULT = 1;
const int COMPLETE_RESULT = 2;
const int SAVE_CELL = 3;

typedef Map<String, dynamic> RequestCreater(int type, [Object request]);

RequestCreater requestChannel() {
  int requestId = 0;
  return (type, [request]) =>
      {'id': requestId++, 'type': type, 'request': request};
}

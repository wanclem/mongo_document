library;

import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';
import 'dart:io';

void main() {
  var raf = File(r'c:\projects\mongo_document_db_driver\debug_data1.bin').openSync();
  var len = raf.lengthSync();
  var lenBuffer = BsonBinary(4);
  var readPos = 0;
  var counter = 0;
  while (raf.positionSync() < len) {
    raf.readIntoSync(lenBuffer.byteList);
    lenBuffer.rewind();
    var messageLen = lenBuffer.readInt32();
    print('$messageLen');
    readPos += messageLen;
    counter++;
    print('counter: $counter readPos $readPos');
    raf.setPositionSync(readPos);
  }
}

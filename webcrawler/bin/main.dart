import 'package:webcrawler/webcrawler.dart' as webcrawler;
import 'package:http/http.dart'; // Contains a client for making API calls
import 'dart:io'; //Contains file stream
import 'dart:isolate'; 
import 'dart:async';
import 'package:stream_channel/stream_channel.dart';

//main
void main(List<String> arguments) async {

  //set variable
  var path = "", depth = 0;
  

  //open file using user input path
  print("Please input filepath/filename.formate: ");
  path = stdin.readLineSync();

  File file = new File(path);
  List<String> urls = file.readAsLinesSync();

  //take user input for depth of crawl
  print("Please input the depth: ");
  depth = int.parse(stdin.readLineSync());

  //crawl for each link in the file
  var ourReceivePort = new ReceivePort();

  Isolate isolate = await Isolate.spawn(webcrawler.crawler, ourReceivePort.sendPort);
  var sendPort = await ourReceivePort.first;


  for (var i in urls){
    sendPort.send(["crawl", i, depth]);
  }

  ourReceivePort = new ReceivePort();
  //var msg = await ourReceivePort.first;
  ourReceivePort.listen((msg) async{
    print(msg);
    isolate.kill(priority: Isolate.immediate);
  });

  //end message
  await print("Successfully crawlled the web.\n");

  return;
}
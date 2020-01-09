import 'dart:convert'; // Contains the JSON encoder
import 'dart:io'; //Contains file stream
import 'dart:collection'; // Contains Set
import 'package:http/http.dart'; // Contains a client for making API calls
import 'package:html/parser.dart'; // Contains HTML parsers to generate a Document object
import 'package:html/dom.dart'; // Contains DOM related classes for extracting data from elements
import "dart:isolate";
import 'dart:async';
import 'package:stream_channel/stream_channel.dart';
import 'package:synchronized/synchronized.dart';

//#save the html page given the requested html response and link
void saveHtml(Response response, String url) async {

  //set variable
  // Client client = new Client();
  // Response response = await client.get(url);

  String page = response.body.toString();
  var filename = url;

  //use the url as the filename and .html extension
  filename = filename.replaceAll("/", "_" ).replaceAll(":", "_").replaceAll(".", "_").replaceAll("?", "_").replaceAll("=", "_");
  filename = filename.replaceAll(",", "_" ).replaceAll("\"", "_").replaceAll("\\", "_").replaceAll("[", "_").replaceAll("]", "_");
  filename = filename.replaceAll(";", "_" ).replaceAll("|", "_").replaceAll("*", "_").replaceAll("<", "_").replaceAll(">", "_");
  var path = "./output/" + filename + ".html";

  //create, open, and write infile
  File file = new File(path);
  file.openWrite().write(page);
  file.openWrite().close();
  
  print("$url, saved!");

  return;

}

void crawler(SendPort sendPort) async {
  
  var ourReceivePort = ReceivePort();
  sendPort.send(ourReceivePort.sendPort);

  //#declear sets to differentiate between visited and tovisit
  LinkedHashSet<String> visited = new LinkedHashSet();
  HashMap actors = new HashMap<int, Isolate>();
  var lock = new Lock();
  int actorCount = 0;
  ourReceivePort.listen((msg) async {
    
    if (msg[0] == "crawl"){
      var url = msg[1];
      var depth = msg[2];

      if (!(visited.contains(url)) & (depth>0))
      {
        visited.add(url);
        await lock.synchronized(()async{
          actorCount = actorCount + 1;
          Isolate i = await Isolate.spawn(getUrl, [ourReceivePort.sendPort, url, depth, actorCount]);
          actors[actorCount] = i;
        });
      }
    }
    else if(msg[0] == "end"){
      int actor = msg[1];
      //C:\Users\anupa\OneDrive\Desktop\links.txt print(actor);

      //lock this block
      Isolate i = actors[actor];
      actors.remove(actor);
      //i.kill(priority: Isolate.immediate);
      //print(actors);
      if (actors.isEmpty){
        sendPort.send("kill");
      }
    } 
  });
}

void getUrl(List lst ) async {

  SendPort sendPort = lst[0];
  var url = lst[1];
  var depth = lst[2];
  var actorCount = lst[3];
  var client = Client();

  if (depth <= 0 ){
    sendPort.send(["end", actorCount]);
    return;
  }

  try {
    Response response = await client.get(url);
    saveHtml(response, url); //save the requested page

    //parse the html page
    var document = parse(response.body);
    List<Element> links = document.querySelectorAll('a'); //find all the anchor tag in the document

    for (var link in links) {

      try {
        var absolute = link.attributes['href'];
  
        if (absolute.startsWith("http") | absolute.startsWith("/http")){
          absolute = absolute;
        }
        else{
          absolute = url + "////" +absolute;
          absolute = absolute.replaceFirst("//////", "/").replaceFirst("/////", "/").replaceFirst("////", "/");           
        }
        sendPort.send(["crawl", absolute, depth-1]);
      }
    
      catch (e) {
      }
    }
  }

  catch (e) {
  print("$url caught");
  }

  sendPort.send(["end", actorCount]);
}
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eduprog Flutter Realtime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Eduprog Flutter Realtime'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  double _curPrice = 0;
  Color _colPrice = Colors.yellow;
  List<Map> _lstRunningTrade = [];
  int _curRow = 0;
  int _maxRow = 13;

  Widget getRunningTradeTable(){

    Widget w;
    List<Widget> lst = [];
    for (int i = 0; i < _lstRunningTrade.length; i++){
      lst.add(DefaultTextStyle(
        style: TextStyle(color: _lstRunningTrade[i]["side"].toString() == "Sell" ? Colors.greenAccent : Colors.redAccent),
        child: Container(
          color: Color.fromRGBO(20, 20, 15, 1.0),
          child: Container(
            color: i == _curRow ? Colors.grey.withOpacity(0.2) : Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    _lstRunningTrade[i]["timestamp"].toString().substring(11, 19), //. 2020-02-11T10:38:00.059Z
                    style: TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _lstRunningTrade[i]["symbol"].toString(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),Expanded(
                  flex: 2,
                  child: Text(
                    formatDigitGroupDbl(double.parse(_lstRunningTrade[i]["price"].toString())),
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    _lstRunningTrade[i]["side"].toString(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    formatDigitGroupInt(int.parse(_lstRunningTrade[i]["size"].toString())),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ));
      lst.add(Container(
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(width: 1, color: Colors.white)
            ),
          )
      ),);
    }

    w = Container(
      //color: Color.fromRGBO(15, 15, 15, 0.9),
      color: Color.fromRGBO(0, 115, 164, 1.0),
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    "Time",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Symbol",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),Expanded(
                  flex: 2,
                  child: Text(
                    "Price",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "B/S",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Vol.",
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,

                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(width: 1, color: Colors.white)
                ),
              )
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: lst,
              ),
            ),
          )
        ],
      ),
    );
    return w;
  }

  String formatDigitGroupDbl(double val){
    String mOut = "";
    if (val != null){

      mOut = NumberFormat("#,###.00").format(val);

    }
    return mOut;
  }


  String formatDigitGroupInt(int val){
    String mOut = "";
    if (val != null){
      mOut = NumberFormat("#,###").format(val);
    }
    return mOut;
  }

  @override
  Widget build(BuildContext context) {
    IconData priceIcon = Icons.remove;
    if (_colPrice == Colors.green){
      priceIcon = Icons.arrow_upward;
    }else if (_colPrice == Colors.red){
      priceIcon = Icons.arrow_downward;
    }
    return Scaffold(

      body: SafeArea(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                color: Color.fromRGBO(0, 115, 164, 1.0),
                alignment: Alignment.center,
                child: Text("${widget.title}", style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FlatButton(
                      color: Colors.red,
                      textColor: Colors.white,
                      onPressed: () {
                        var channel = IOWebSocketChannel.connect('wss://www.bitmex.com/realtime');
                        channel.sink.add('{"op": "subscribe", "args": ["trade:XBTUSD"]}');
                        channel.stream.listen((message) {
                          var jResponse = json.decode(message);
                          print(jResponse);

                          if (jResponse["table"] == "trade"){
                            _curRow++;
                            if (_curRow > _maxRow){
                              _curRow = 0;
                            }
                            _curPrice = double.parse(jResponse["data"][0]["price"].toString());
                            String tickDirection = jResponse["data"][0]["tickDirection"].toString();
                            if (tickDirection.indexOf("Minus") >= 0){
                              _colPrice = Colors.red;
                            }else if (tickDirection.indexOf("Plus") >= 0){
                              _colPrice = Colors.green;
                            }else{
                              _colPrice = Colors.yellow;
                            }

                            if (_lstRunningTrade.length <= _maxRow){
                              _lstRunningTrade.add(jResponse["data"][0]);
                            }else{
                              //. update frame
                              _lstRunningTrade[_curRow] = jResponse["data"][0];

                            }

                            //. refresh
                            setState(() {

                            });
                          }
                        });
                      },
                      shape: RoundedRectangleBorder(side: BorderSide(
                          color: Colors.red,
                          width: 1,
                          style: BorderStyle.solid
                      ), borderRadius: BorderRadius.circular(50)),
                      child: Text(
                        "Start Subscribe",
                        style: TextStyle(fontSize: 15.0),
                      ),

                    )
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.grey, width: 1)
                ),
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Text("Bitcoin Price", style: TextStyle(
                          fontSize: 12,
                        color: Colors.orange
                      )),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text( "\$${formatDigitGroupDbl(_curPrice)} USD", style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: _colPrice
                          ),),
                          SizedBox(width: 10,),
                          Icon(priceIcon, size: 40, color: _colPrice,)
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: getRunningTradeTable()
              )
            ],

          ),

        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

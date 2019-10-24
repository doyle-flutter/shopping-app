import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() => runApp(
  MaterialApp(
    home: MyApp(),
  )
);

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  StreamController _sc;

  Future getLocalDataAll() async{


    final String _url = "http://localhost:port/item/all";
    var res = await http.Client().get(_url);
    return parse(res.body);
  }

  parse(resbody){
    var result = json.decode(resbody);
    return result.map((json) => Products.fromJosn(json)).toList();
  }
  fetchData(){
    return getLocalDataAll().then((v) => _sc.add(v));
  }

  @override
  void initState() {
    _refreshController =
    RefreshController(initialRefresh: false);
    _sc = StreamController();
    fetchData();
    super.initState();
  }

  @override
  void dispose() {
    _sc?.close();
    super.dispose();
  }

  RefreshController _refreshController;

  void _onRefresh() async{
    await Future.delayed(Duration(seconds: 1), ()=>fetchData());
    _refreshController.refreshCompleted();
  }

  void _onLoading() async{
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: SingleChildScrollView(
          child: Container(
            child: Column(
              children: <Widget>[
                StreamBuilder(
                  stream: _sc.stream,
                  builder: (context, snap){
                    if(snap.hasData){
                      return Container(
                        margin: EdgeInsets.only(
                          top: 50.0
                        ),
                        width: 200,
                        height: 500,
                        child: ListView.builder(
                          itemCount: snap.data.length,
                          itemBuilder: (context, int index){
                            return GestureDetector(
                              child: Container(
                                height: 200,
                                margin: EdgeInsets.only(
                                  top: 10.0
                                ),
                                color: Colors.grey[300],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text("상품번호 : "+snap.data[index].id.toString()),
                                    Text("상품명 : "+snap.data[index].productName.toString()),
                                    Text("금액 : "+snap.data[index].price.toString()),
                                    Text("수량 : "+snap.data[index].ea.toString())
                                  ],
                                ),
                              ),
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailPage(
                                      id: index,
                                    )
                                  )
                                );
                              },
                            );
                          },
                        ),
                      );
                    }
                    else{
                      return CircularProgressIndicator();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class Products{
  int id;
  String productName;
  int price;
  int ea;

  Products({this.id, this.ea, this.price, this.productName});

  factory Products.fromJosn(json){
    return Products(
      id: json['id'] as int,
      ea: json['ea'] as int,
      price: json['price'] as int,
      productName: json['productName'] as String
    );
  }

}


class DetailPage extends StatefulWidget {

  int id;
  DetailPage({this.id});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {

  Future getItem() async{
    final String _url = "http://localhost:port/item/${widget.id.toString()}";
    var res = await http.Client().get(_url);
    var result = json.decode(res.body);
    return Products.fromJosn(result);
  }


  Future buyItem(int id) async{
    final String _url = "http://localhost:port/buy/item/${id.toString()}";
    var res = await http.Client().post(_url);
    print(res.body);
    if(res.body != "OK"){
      print("구매실패");
      return Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => FalsePage()
        )
      );
    }
    else{
      return Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CompletePage()
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: (){
            Navigator.pop(context);
          },
          child: Row(
            children: <Widget>[
              Icon(
                Icons.arrow_back_ios,
                size: 20,
              ),
              Text(
                "Back",
                style: TextStyle(
                  fontSize: 16
                ),
              )
            ],
          ),
        ),
      ),
      body:SingleChildScrollView(
        child: Container(
          width: 500,
          margin: EdgeInsets.only(
            top: 50.0
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              FutureBuilder(
                future: getItem(),
                builder: (context, snap){
                  if(snap.hasData){
                    return Container(
                      width: 300,
                      height: 200,
                      margin: EdgeInsets.only(
                          top: 10.0
                      ),
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text("상품번호 : "+snap.data.id.toString()),
                          Text("상품명 : "+snap.data.productName.toString()),
                          Text("금액 : "+snap.data.price.toString()),
                          Text("수량 : "+snap.data.ea.toString())
                        ],
                      ),
                    );
                  }
                  else{
                    return CircularProgressIndicator();
                  }
                },
              ),
              RaisedButton(
                onPressed: () => buyItem(widget.id),
                child: Text("구매"),
              )
            ],
          ),
        ),
      ),
    );
  }
}


class CompletePage extends StatefulWidget {
  @override
  _CompletePageState createState() => _CompletePageState();
}

class _CompletePageState extends State<CompletePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(
              top: 50.0
          ),
          child: Column(
            children: <Widget>[
              Text("완료"),
              RaisedButton(
                child: Text("홈으로"),
                onPressed: (){
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => MyApp()
                    )
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class FalsePage extends StatefulWidget {
  @override
  _FalsePageState createState() => _FalsePageState();
}

class _FalsePageState extends State<FalsePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(
              top: 50.0
          ),
          child: Column(
            children: <Widget>[
              Text("재고부족 구매실패"),
              RaisedButton(
                child: Text("홈으로"),
                onPressed: (){
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => MyApp()
                      )
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}


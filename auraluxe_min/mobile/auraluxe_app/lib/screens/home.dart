import 'package:flutter/material.dart'; import '../services.dart';
class Home extends StatefulWidget{ const Home({super.key}); @override State<Home> createState()=>_S(); }
class _S extends State<Home>{ final api=Api(); List mixes=[]; bool load=true;
  @override void initState(){ super.initState(); api.home().then((d){ setState((){ mixes=d['mixes']??[]; load=false; });}); }
  @override Widget build(BuildContext c)=>load?const Center(child:CircularProgressIndicator()):ListView(children:[for(final m in mixes) Card(child:ListTile(leading:const Icon(Icons.playlist_play),title:Text(m['title']??'Mix'),subtitle:Text('${(m['items']??[]).length} tracks')))]);
}

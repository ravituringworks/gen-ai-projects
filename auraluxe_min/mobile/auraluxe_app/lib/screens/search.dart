import 'package:flutter/material.dart'; import '../services.dart';
class Search extends StatefulWidget{ const Search({super.key}); @override State<Search> createState()=>_S(); }
class _S extends State<Search>{ final api=Api(); final t=TextEditingController(text:'lofi'); List r=[]; bool l=false;
  void go() async{ setState(()=>l=true); r=await api.search(t.text); setState(()=>l=false); }
  @override Widget build(BuildContext c)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:TextField(controller:t)),const SizedBox(width:8),FilledButton(onPressed:go,child:const Text('Search'))])), if(l)const LinearProgressIndicator(), Expanded(child:ListView(children:[for(final x in r) ListTile(leading:const Icon(Icons.music_note),title:Text(x['title']??''),subtitle:Text(x['artist']??''))]))]); }

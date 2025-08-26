import 'package:flutter/material.dart'; import 'package:just_audio/just_audio.dart'; import '../services.dart';
class Now extends StatefulWidget{ const Now({super.key}); @override State<Now> createState()=>_S(); }
class _S extends State<Now>{ final api=Api(); final p=AudioPlayer(); String st='loading'; Map? man;
  @override void initState(){ super.initState(); () async { man=await api.manifest('demo'); final url=man?['url']; if(url!=null){ try{ await p.setUrl(url); await p.play(); st='playing'; } catch(e){ st='error $e'; } } else { st='no url'; } if(mounted)setState((){}); }(); }
  @override void dispose(){ p.dispose(); super.dispose(); }
  @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Now Playing',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)), const SizedBox(height:8), Text('Status: $st'), if(man!=null) Text('URL: ${man!['url']}')])); }

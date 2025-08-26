import 'package:flutter/material.dart'; import 'screens/home.dart'; import 'screens/search.dart'; import 'screens/now.dart';
class AApp extends StatefulWidget{ const AApp({super.key}); @override State<AApp> createState()=>_S(); }
class _S extends State<AApp>{ int i=0; final pages=const[Home(),Search(),Now()];
  @override Widget build(BuildContext c)=>MaterialApp(home:Scaffold(appBar:AppBar(title:const Text('Auraluxe')),body:pages[i],bottomNavigationBar:NavigationBar(selectedIndex:i,onDestinationSelected:(v)=>setState(()=>i=v),destinations:const[NavigationDestination(icon:Icon(Icons.home),label:'Home'),NavigationDestination(icon:Icon(Icons.search),label:'Search'),NavigationDestination(icon:Icon(Icons.music_note),label:'Now')]),)); }

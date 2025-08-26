import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget{ const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage>{
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  @override Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2, child: Padding(padding: const EdgeInsets.all(24), child:
              Form(key:_formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Market Intelligence', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(controller:_email, decoration: const InputDecoration(labelText:'Email')),
                TextFormField(controller:_pw, obscureText:true, decoration: const InputDecoration(labelText:'Password')),
                const SizedBox(height: 16),
                FilledButton(onPressed:() async {
                  try {
                    await Supabase.instance.client.auth.signInWithPassword(email: _email.text, password: _pw.text);
                    if (context.mounted) context.go('/signals');
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
                  }
                }, child: const Text('Sign in')),
              ]))
            ))
        )
      )
    );
  }
}

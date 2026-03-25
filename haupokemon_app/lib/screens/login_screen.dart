import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  final _playerNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    setState(() => _isLoading = true);
    
    // Check if the user is logging in or creating a new account natively
    try {
      if (_isLogin) {
        final response = await apiService.login(
          _usernameController.text,
          _passwordController.text,
        );
        if (response.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', response['token']);
          await prefs.setInt('player_id', response['player']['id']);
          await prefs.setString('player_name', response['player']['player_name'] ?? 'Monster Admin');
          await prefs.setString('username', response['player']['username'] ?? 'Player');
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _showError(response['message'] ?? 'Login failed');
        }
      } else {
        // Registration mode
        if (_playerNameController.text.isEmpty || _usernameController.text.isEmpty || _passwordController.text.isEmpty) {
          _showError('Please fill out all fields.');
          setState(() => _isLoading = false);
          return;
        }

        final registerData = {
          'player_name': _playerNameController.text,
          'username': _usernameController.text,
          'password': _passwordController.text,
        };

        final response = await apiService.postData('auth/register', registerData);
        if (response.containsKey('message') && response['message'] == 'Account created successfully') {
          // Now auto-login immediately for the user!
          final loginResponse = await apiService.login(_usernameController.text, _passwordController.text);
          if (loginResponse.containsKey('token')) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('jwt_token', loginResponse['token']);
            await prefs.setInt('player_id', loginResponse['player']['id']);
            await prefs.setString('player_name', loginResponse['player']['player_name'] ?? 'Monster Admin');
            await prefs.setString('username', loginResponse['player']['username'] ?? 'Player');
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          _showError(response['message'] ?? 'Registration rejected');
        }
      }
    } catch (e) {
      _showError('Connection error: $e');
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('HAUPokemon Secure Area')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.catching_pokemon, size: 100, color: Colors.red),
              const SizedBox(height: 30),
              Text(
                _isLogin ? 'Welcome Back!' : 'Join HAUPokemon',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              if (!_isLogin)
                TextField(
                  controller: _playerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Player Name (e.g. Ash Ketchum)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              if (!_isLogin) const SizedBox(height: 16),
              
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: _isLogin ? 'Username' : 'Username (For Logging In)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_circle),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submit,
                        child: Text(_isLogin ? 'LOGIN' : 'CREATE ACCOUNT', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin ? 'Don\'t have an account? Sign up' : 'Already have an account? Log in',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

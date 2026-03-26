// dart format off
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Ec2ManagementScreen extends StatefulWidget {
  const Ec2ManagementScreen({super.key});

  @override
  _Ec2ManagementScreenState createState() => _Ec2ManagementScreenState();
}

class _Ec2ManagementScreenState extends State<Ec2ManagementScreen> {
  String _status = 'Unknown';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  void _fetchStatus() async {
    setState(() => _isLoading = true);
    try {
      final response = await apiService.getEc2Status();
      setState(() {
        _status = response['state'] ?? 'Unknown';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading status';
        _isLoading = false;
      });
    }
  }

  void _startInstance() async {
    try {
      await apiService.startEc2Instance();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Start command sent.')));
      _fetchStatus();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _stopInstance() async {
    try {
      await apiService.stopEc2Instance();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stop command sent.')));
      _fetchStatus();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AWS EC2 Manager')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_circle,
                    size: 100,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Instance Status:',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _status == 'running'
                          ? Colors.green
                          : const Color.fromARGB(255, 5, 5, 5),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _startInstance,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('ON'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 189, 57, 57),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _stopInstance,
                        icon: const Icon(Icons.stop),
                        label: const Text('OFF'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: _fetchStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Status'),
                  ),
                ],
              ),
      ),
    );
  }
}

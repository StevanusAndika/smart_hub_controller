import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP8266 Controller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ESPControlPage(),
    );
  }
}

class ESPControlPage extends StatefulWidget {
  const ESPControlPage({Key? key}) : super(key: key);

  @override
  ESPControlPageState createState() => ESPControlPageState();
}

class ESPControlPageState extends State<ESPControlPage> {
  bool _isConnected = false;
  bool _ledStatus = false;
  final String _apIP = '192.168.4.1';
  Map<String, dynamic> _deviceInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _getDeviceInfo();
  }

  Future<void> _checkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isConnected = connectivityResult.contains(ConnectivityResult.wifi);
      });
    }
  }

  Future<void> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};

    try {
      if (kIsWeb) {
        deviceData = _readWebBrowserInfo(await deviceInfo.webBrowserInfo);
      } else {
        if (Platform.isAndroid) {
          deviceData = _readAndroidBuildData(await deviceInfo.androidInfo);
        } else if (Platform.isIOS) {
          deviceData = _readIosDeviceInfo(await deviceInfo.iosInfo);
        } else if (Platform.isLinux) {
          deviceData = _readLinuxDeviceInfo(await deviceInfo.linuxInfo);
        } else if (Platform.isMacOS) {
          deviceData = _readMacOsDeviceInfo(await deviceInfo.macOsInfo);
        } else if (Platform.isWindows) {
          deviceData = _readWindowsDeviceInfo(await deviceInfo.windowsInfo);
        }
      }
    } catch (e) {
      deviceData = {'Error:': 'Failed to get device info: $e'};
    }

    if (mounted) {
      setState(() {
        _deviceInfo = deviceData;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo webBrowserInfo) {
    return <String, dynamic>{
      'Browser': '${webBrowserInfo.browserName}',
      'Platform': '${webBrowserInfo.platform}',
      'Vendor': '${webBrowserInfo.vendor}',
      'User Agent': '${webBrowserInfo.userAgent}',
    };
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'Device': build.model,
      'Manufacturer': build.manufacturer,
      'Brand': build.brand,
      'Product': build.product,
      'OS': 'Android ${build.version.release}',
      'SDK': build.version.sdkInt.toString(),
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'Device': data.name,
      'Model': data.model,
      'System': 'iOS ${data.systemVersion}',
      'UUID': data.identifierForVendor,
    };
  }

  Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo data) {
    return <String, dynamic>{
      'Name': data.name,
      'Version': data.version,
      'ID': data.id,
    };
  }

  Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo data) {
    return <String, dynamic>{
      'Computer': data.computerName,
      'Model': data.model,
      'Kernel': data.kernelVersion,
      'OS': data.osRelease,
    };
  }

  Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo data) {
    return <String, dynamic>{
      'Computer': data.computerName,
      'OS': 'Windows ${data.productName}',
      'Version': data.displayVersion,
    };
  }

  Future<void> _controlLED(String command) async {
    try {
      final response = await http.get(Uri.parse('http://$_apIP/led/$command'));
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _ledStatus = (command == 'on');
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('LED ${command.toUpperCase()} berhasil'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengontrol LED'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi untuk membuat warna dengan opacity
  Color _withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontrol ESP8266'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade700, Colors.purple.shade600],
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade800,
              Colors.purple.shade600,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isSmallScreen ? screenWidth * 0.9 : 500,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _withOpacity(Colors.white, 0.15),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _withOpacity(Colors.black, 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: _withOpacity(Colors.white, 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Kontrol ESP8266 (Access Point)',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _withOpacity(Colors.white, 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _withOpacity(Colors.deepPurpleAccent, 0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.wifi, 'SSID:', 'ESP8266_AP'),
                        _buildInfoRow(Icons.language, 'Alamat IP:', '192.168.4.1'),
                        _buildInfoRow(
                          _isConnected ? Icons.check_circle : Icons.error,
                          'Status:',
                          _isConnected ? 'Terhubung' : 'Tidak Terhubung',
                          _isConnected ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Kontrol LED onboard ESP8266 dengan tombol di bawah:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 25),
                  isSmallScreen
                      ? Column(
                          children: [
                            _buildControlButton('LED ON', Icons.power, Colors.green, 'on'),
                            const SizedBox(height: 15),
                            _buildControlButton('LED OFF', Icons.power_off, Colors.red, 'off'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlButton('LED ON', Icons.power, Colors.green, 'on'),
                            _buildControlButton('LED OFF', Icons.power_off, Colors.red, 'off'),
                          ],
                        ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _ledStatus
                          ? _withOpacity(Colors.green, 0.2)
                          : _withOpacity(Colors.red, 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _ledStatus
                            ? _withOpacity(Colors.greenAccent, 0.5)
                            : _withOpacity(Colors.redAccent, 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _ledStatus ? Icons.lightbulb : Icons.lightbulb_outline,
                          color: _ledStatus ? Colors.greenAccent : Colors.redAccent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Status: ${_ledStatus ? 'LED HIDUP' : 'LED MATI'}',
                          style: TextStyle(
                            color: _ledStatus ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  ExpansionTile(
                    title: const Text(
                      'Informasi Device',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: const Icon(Icons.phone_android, color: Colors.white70),
                    backgroundColor: _withOpacity(Colors.black, 0.1),
                    collapsedBackgroundColor: _withOpacity(Colors.black, 0.1),
                    textColor: Colors.white,
                    iconColor: Colors.white70,
                    collapsedIconColor: Colors.white70,
                    children: [
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _deviceInfo.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${entry.key}: ',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${entry.value}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Dibuat dengan Flutter & ESP8266 | © 2023',
                    style: TextStyle(
                      color: _withOpacity(Colors.white, 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkConnection,
        backgroundColor: _isConnected
            ? _withOpacity(Colors.green, 0.8)
            : _withOpacity(Colors.red, 0.8),
        child: Icon(
          _isConnected ? Icons.wifi : Icons.wifi_off,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 18),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String text, IconData icon, Color color, String command) {
    return ElevatedButton(
      onPressed: _isConnected ? () => _controlLED(command) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _withOpacity(color, 0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
        shadowColor: _withOpacity(color, 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
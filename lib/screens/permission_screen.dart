import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/app_theme.dart';
import 'home_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _requesting = false;
  bool _denied = false;
  bool _permanentlyDenied = false;

  Future<int> _androidSdk() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  Future<void> _requestPermission() async {
    setState(() {
      _requesting = true;
      _denied = false;
      _permanentlyDenied = false;
    });

    bool granted = false;

    if (!Platform.isAndroid) {
      granted = true;
    } else {
      final sdk = await _androidSdk();

      if (sdk >= 30) {
        // Android 11+: MANAGE_EXTERNAL_STORAGE para documentos/arquivos
        final status = await Permission.manageExternalStorage.status;
        if (status.isGranted) {
          granted = true;
        } else {
          final result = await Permission.manageExternalStorage.request();
          granted = result.isGranted;
          if (result.isPermanentlyDenied) {
            setState(() => _permanentlyDenied = true);
          }
        }
      } else {
        // Android < 11: READ_EXTERNAL_STORAGE clássico
        final status = await Permission.storage.status;
        if (status.isGranted) {
          granted = true;
        } else {
          final result = await Permission.storage.request();
          granted = result.isGranted;
          if (result.isPermanentlyDenied) {
            setState(() => _permanentlyDenied = true);
          }
        }
      }
    }

    if (!mounted) return;

    if (granted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() {
        _requesting = false;
        _denied = !_permanentlyDenied;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  size: 64,
                  color: AppTheme.accent,
                ),
              ),

              const SizedBox(height: 32),

              // Título
              const Text(
                'Acesso aos Arquivos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Descrição
              Text(
                'Para abrir seus quadrinhos (.cbr e .cbz), o Leitor HQ precisa de '
                'permissão para acessar os arquivos do dispositivo.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Card informativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ao tocar em "Permitir", o Android abrirá a tela de permissão '
                        'de acesso a todos os arquivos. Toque em "Permitir" nessa tela para continuar.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Mensagem de negação permanente
              if (_permanentlyDenied) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'Permissão bloqueada. Toque em "Abrir Configurações" e ative '
                    '"Permitir gerenciamento de todos os arquivos" manualmente.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_denied) ...[
                Text(
                  'Permissão necessária para ler arquivos .cbr e .cbz.',
                  style: TextStyle(
                    color: Colors.orange.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Botão principal
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _requesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _permanentlyDenied
                        ? 'Abrir Configurações'
                        : _denied
                        ? 'Tentar Novamente'
                        : 'Permitir',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _requesting
                      ? null
                      : _permanentlyDenied
                      ? () => openAppSettings()
                      : _requestPermission,
                ),
              ),

              const SizedBox(height: 16),

              // Pular
              TextButton(
                onPressed: _requesting
                    ? null
                    : () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                child: Text(
                  'Pular por agora',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

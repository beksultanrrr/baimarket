import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Панель управления ведущего: микрофон, камера, переворот, товар.
///
/// Завершение эфира сюда намеренно не входит — оно в шапке, отдельно от
/// частых переключателей, чтобы не завершить трансляцию промахом.
class HostControlsBar extends StatelessWidget {
  const HostControlsBar({
    super.key,
    required this.micEnabled,
    required this.cameraEnabled,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onFlipCamera,
    required this.onPickProduct,
  });

  final bool micEnabled;
  final bool cameraEnabled;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onFlipCamera;
  final VoidCallback onPickProduct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
            active: micEnabled,
            onTap: onToggleMic,
          ),
          _ControlButton(
            icon: cameraEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            active: cameraEnabled,
            onTap: onToggleCamera,
          ),
          _ControlButton(
            icon: Icons.cameraswitch_rounded,
            active: true,
            onTap: onFlipCamera,
          ),
          _ControlButton(
            icon: Icons.shopping_bag_rounded,
            active: true,
            onTap: onPickProduct,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(52, 52),
      onPressed: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFFEC1B6E),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

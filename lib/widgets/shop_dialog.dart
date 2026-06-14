import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../i18n/app_strings.dart';
import '../services/purchase_service.dart';

class ShopDialog extends StatefulWidget {
  const ShopDialog({super.key});
  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog> {
  bool _busy = false;

  Future<void> _buy(String id) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await PurchaseService.instance.buy(id);
    if (mounted) {
      setState(() => _busy = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).shopUnavailableMsg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final svc = PurchaseService.instance;
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('💎 ${s.shop}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(s.diamondPacks,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
              ),
              const SizedBox(height: 8),
              if (!svc.available)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(s.shopUnavailable,
                        style: const TextStyle(color: Colors.white60)),
                  ),
                ),
              for (final pack in PurchaseService.diamondPacks)
                _diamondTile(context, pack, svc.productFor(pack.id)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _diamondTile(BuildContext context, DiamondPack pack, ProductDetails? product) {
    final s = AppStrings.of(context);
    final available = product != null && PurchaseService.instance.available;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF120F22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3498db).withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3498db), Color(0xFF1E3F8B)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.diamond, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${pack.diamonds} ${s.diamonds}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  if (pack.bonus > 0)
                    Text('+ ${pack.bonus} ${s.bonusUpper}',
                        style: const TextStyle(
                            color: Color(0xFFFFCA28), fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498db),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              onPressed: !available || _busy ? null : () => _buy(pack.id),
              child: Text(product?.price ?? 'N/A'),
            ),
          ],
        ),
      ),
    );
  }
}

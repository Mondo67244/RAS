import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:ras_app/basicdata/produit.dart';
import 'package:ras_app/basicdata/style.dart';
import 'package:ras_app/widgets/carteProduit.dart';

class ProductSection extends StatelessWidget {
  final String title;
  final List<Produit> produits;
  final bool isWideScreen;
  final Set<String> souhaits;
  final Set<String> paniers;
  final Function(Produit) onToggleSouhait;
  final Function(Produit) onTogglePanier;

  const ProductSection({
    super.key,
    required this.title,
    required this.produits,
    required this.isWideScreen,
    required this.souhaits,
    required this.paniers,
    required this.onToggleSouhait,
    required this.onTogglePanier,
  });

  @override
  Widget build(BuildContext context) {
    if (produits.isEmpty) return const SizedBox.shrink();

    final ScrollController scrollController = ScrollController();
    final double cardWidth = isWideScreen ? 320 : 300;

    void scrollCards(int direction) {
      final double scrollAmount = cardWidth * 2 * direction;
      final double maxScroll = scrollController.position.maxScrollExtent;
      final double currentScroll = scrollController.offset;
      final double targetScroll =
          (currentScroll + scrollAmount).clamp(0.0, maxScroll);

      scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Row(
            children: [
              Icon(FluentIcons.arrow_right_24_filled,
                  color: styles.bleu, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: isWideScreen ? 420 : 400,
              child: ListView.builder(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: produits.length,
                itemBuilder: (context, index) {
                  final produit = produits[index];
                  return ProductCard(
                    produit: produit,
                    isSouhait: souhaits.contains(produit.idProduit),
                    isPanier: paniers.contains(produit.idProduit),
                    isWideScreen: isWideScreen,
                    onToggleSouhait: () => onToggleSouhait(produit),
                    onTogglePanier: () => onTogglePanier(produit),
                  );
                },
              ),
            ),
            if (produits.length >= 4)
              Positioned(
                left: 0,
                child: _navButton(
                  icon: Icons.arrow_back_ios_new,
                  onPressed: () => scrollCards(-1),
                ),
              ),
            if (produits.length >= 4)
              Positioned(
                right: 0,
                child: _navButton(
                  icon: Icons.arrow_forward_ios,
                  onPressed: () => scrollCards(1),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}
